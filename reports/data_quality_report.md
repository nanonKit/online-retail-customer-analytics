# Data Quality Report & Decision Log — Online Retail II

> Every cleaning rule in `sql/02_staging/01_stg_transactions.sql` traces back to a decision below. Figures are measured on the raw data unless stated.

## Scope

| Item | Value |
|---|---|
| Source | UCI Online Retail II (`online_retail_II.xlsx`, 2 sheets) |
| Period | 2009-12-01 07:45 → 2011-12-09 12:50 |
| Raw rows | 1,067,371 (525,461 + 541,910) |
| Grain | 1 row = 1 product line in 1 invoice |
| Currency | GBP (£) |

## Decision Log

| # | Issue | Evidence | Decision | Rationale | Impact |
|---|---|---|---|---|---|
| 1 | **Sheet overlap** 2010-12-01 → 12-09 | 1,088 invoices / 22,523 rows in both sheets · `EXCEPT ALL` = 0 (identical rows) | Drop sheet-1 rows `>= 2010-12-01` | Each month must come from one sheet | Prevents double-counting the pre-Christmas peak |
| 2 | **Exact duplicate rows** | 11,812 rows (1.13%) · InvoiceDate is per-invoice (>99.8%), so true re-picks can't be distinguished | Remove (`SELECT DISTINCT`) | Most likely system/export duplicates | **Limitation:** if some were real re-picks, revenue is understated by ≤ ~1.13% of rows |
| 3 | **Cancellations** (`C` invoices) | 19,494 rows · −£1,526,668 (7.59% of gross) | **Keep and net against sales** · flag `is_cancellation` | Deleting would overstate revenue ~8% and lose a churn signal | Correct net revenue |
| 4 | **Data-entry errors** (ordered then cancelled within minutes) | 581483↔C581484 ±80,995 units (12 min) · 541431↔C541433 ±74,215 (16 min) | Handled by #3 (nets to 0) | Never delete only the `C` row | Prevents £245,653 of phantom revenue |
| 5 | **Bad-debt adjustment** (`A` invoices, StockCode `B`) | 6 rows · −£147,614 (0.73%) | Exclude from sales | Accounting entry, not a sale | Few rows, large amount → check amounts, not just row counts |
| 6 | **Inventory write-offs** (Qty < 0, not `C`) | 3,457 rows · Price = 0 · no customer · "printing smudges / thrown away" | Exclude from sales | Stock adjustment, not a transaction | No revenue impact · correct unit counts |
| 7 | **Zero-price lines** (Qty > 0, Price = 0) | 2,745 rows | Exclude from sales / basket | Free samples or entry errors | Cleaner baskets |
| 8 | **Non-product StockCodes** | 4,792 rows · +£852,537 (4.24%) · postage, manual, discount, fees, gift vouchers, test | Exclude from product revenue via **explicit denylist** (+ `UPPER`) | A regex also caught real products (DCGS*, SP1002, PADS) | Product revenue excludes shipping/fees |
| 9 | **Missing Customer ID** | ~¼ of lines | Keep in revenue facts · exclude from customer models | Guest checkout | RFM/CLV use identified customers only |
| 10 | **All columns ingested as VARCHAR** | `all_varchar` avoids `C489449` → DOUBLE cast error | Explicit `CAST` in staging | Control types ourselves | — |
| 11 | **InvoiceDate stored as Excel serial** | `40148.3229…` = 2009-12-01 07:45 | `excel_to_ts()` macro | Day 0 = 1899-12-30; serial 25569 = 1970-01-01 | — |
| 12 | **Text hygiene** | Leading spaces in Description · StockCode `M` vs `m` | `TRIM(Description)` · `UPPER(StockCode)` | Same product counted twice otherwise | — |
| 13 | **Wholesale outliers** | Customer 13902 (DK): 19,152 / 12,960 units @ £0.10, not cancelled | **Keep** · wholesale = avg units/order ≥ 500 | Outlier ≠ error · 6.4% of customers, 31.5% of revenue | RFM scored separately by customer type (sensitivity check: 250) |
| 14 | **Partial month** | Data ends 2011-12-09 (Dec 2011 = 9 days) | Annotate; compare like-for-like | Low last bar ≠ decline | — |
| 15 | **Cancelled sales in CLV input** | Top-CLV customer 16446 = a cancelled 80,995-unit order (CLV export used sales only) | Remove sales with a matching later cancellation (customer, stock code, −qty, price) via `NOT EXISTS` | Fix the rule at the source, not customer by customer | Last-12m sales −£421,631 · CLV vs actual +2.3% → +1.8% · Limitation: partial cancellations not netted |
| 16 | **Inconsistent product names** | `RETROSPOT` vs `RETRO SPOT`, `SET OF4` vs `SET OF 4` | Not fixed; basket rule typing uses a descriptor-word heuristic | No product master available | Some variant rules may be labelled cross-sell |

## Target Types

| Column | Raw | Target | Rule |
|---|---|---|---|
| Invoice | VARCHAR | VARCHAR | Contains letters (`C`, `A`) |
| StockCode | VARCHAR | VARCHAR | `UPPER()` |
| Description | VARCHAR | VARCHAR | `TRIM()` |
| Quantity | VARCHAR | INTEGER | |
| InvoiceDate | VARCHAR | TIMESTAMP | `excel_to_ts()` |
| Price | VARCHAR | DECIMAL(18, 4) | Money → exact decimal (DOUBLE accumulates rounding error) |
| Customer ID | VARCHAR | VARCHAR | An identifier, not a number |
| Country | VARCHAR | VARCHAR | |

## Implementation

| Decision | Where |
|---|---|
| #1 | `stg_transactions` CTE `no_overlap` |
| #2 | CTE `deduped` |
| #10 #11 #12 | CTE `typed` (`CAST`, `excel_to_ts`, `TRIM`, `UPPER`) |
| #3 #5 #6 #7 #8 | `CASE` → `row_type` (non_product checked before cancellation) |
| #9 | flag `has_customer` |
| #13 | `mart_customer_rfm` |
| #14 | EDA / dashboard annotation |
| #15 | `04_marts/04_export_for_python.sql` |

## Resolved checks
- Customers with net monetary ≤ 0: **43** → excluded from RFM/CLV (kept in dashboard as `Excluded`)
- Ambiguous codes `DCGS0068` ("ebay") and `C3` → denylist; other DCGS codes kept as products
