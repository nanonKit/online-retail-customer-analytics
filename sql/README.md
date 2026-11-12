# SQL Layer

All cleaning, transformation and analysis is done in SQL (DuckDB). Python only reads the Parquet files exported from `04_marts`.

## Run Order
| Folder | Purpose | Creates |
|---|---|---|
| `00_ingest/` | Load both Excel sheets (`all_varchar`), define macros | `raw_transactions`, `excel_to_ts()` |
| `01_quality_checks/` | One file per data issue → evidence for the decision log | (read-only) |
| `02_staging/` | Remove sheet overlap & duplicates, cast types, classify `row_type` | `stg_transactions` |
| `03_analysis/` | Business questions: monthly trend, Pareto, cohort retention, basket profile | (read-only) + `basket_lines` |
| `04_marts/` | Final tables + `COPY ... TO data/marts/*.parquet` | `fct_sales`, `mart_customer_*`, Parquet |

Notebook dependency: `04_marts/04_export_for_python.sql` → `notebooks/03_clv.ipynb` → `04_marts/06_mart_customer_value.sql` → `07_export_for_powerbi.sql`.

**Rebuild (PowerShell, from repo root):**
```powershell
Get-ChildItem sql\00_ingest, sql\02_staging, sql\04_marts -Filter *.sql | Sort-Object FullName | ForEach-Object { duckdb project.duckdb ".read $($_.FullName -replace '\\','/')" }
```
> Close the DBeaver connection first — a `.duckdb` file allows one writer at a time.
> Scripts use absolute paths (`E:/Data_Analytic/Online Retail II/...`); replace with your clone path.

## Conventions
- File names `NN_snake_case.sql`, numbered in run order
- Upper-case keywords/functions, lower-case identifiers (`.sqlfluff`)
- One question = one file
- Format: `sqlfluff fix sql/`
