# Dashboard Spec — Online Retail II · Customer Value Overview (1 page, 1280×720)

ตัวเลขทั้งหมดตรวจจาก `data/marts/powerbi/*.parquet` (ไม่มี slicer)

## Measures ที่แก้ (ตัวหารใช้ ALLSELECTED → % รวมกันได้ 100% เฉพาะกลุ่มที่แสดง)
```DAX
% Customers   = DIVIDE ( [Customers],   CALCULATE ( [Customers],   ALLSELECTED ( dim_customer[action_group] ) ) )
% Net Revenue = DIVIDE ( [Net Revenue], CALCULATE ( [Net Revenue], ALLSELECTED ( dim_customer[action_group] ) ) )
% CLV 12m     = DIVIDE ( [CLV 12m],     CALCULATE ( [CLV 12m],     ALLSELECTED ( dim_customer[action_group] ) ) )
```
เหตุผล: `REMOVEFILTERS` ล้าง visual filter ด้วย → ตัวหารรวม guest (£2.57M) + Excluded → Retain แสดง 70% แทน 81%

## Layout
| Visual | X | Y | W | H |
|---|---|---|---|---|
| Title | 20 | 12 | 780 | 48 |
| Slicer customer_type | 820 | 12 | 210 | 48 |
| Slicer Year | 1050 | 12 | 210 | 48 |
| KPI Card (new) | 20 | 72 | 1240 | 100 |
| Line | 20 | 188 | 1240 | 200 |
| Cohort matrix | 20 | 404 | 610 | 296 |
| Action groups bar | 650 | 404 | 610 | 296 |

## Content
**Title:** Online Retail II — Customer Value Overview · Subtitle: UK online gift retailer · 1 Dec 2009 – 9 Dec 2011 · Net of cancellations

**KPI:** Net Revenue £18.93M · Customers 5,875 · Retention M1 23.0% · CLV 12m £8.14M
(Year = 2011: £9.01M · 4,231 customers)

**Line** — Title: "Revenue peaks every November — 2011 ahead of 2010 by 2.7% like-for-like"
Subtitle: "Dec 2011 covers 9 days only" · X Month, Y Net Revenue, Legend Year, filter Year 2010–2011
| £K | Jan | Feb | Mar | Apr | May | Jun | Jul | Aug | Sep | Oct | Nov | Dec |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2010 | 605 | 525 | 752 | 636 | 606 | 670 | 616 | 662 | 842 | 1,069 | 1,395 | 758 |
| 2011 | 579 | 499 | 679 | 482 | 731 | 724 | 677 | 701 | 1,011 | 1,062 | 1,427 | 440* |

**Cohort matrix** — Title: "About 1 in 4 new customers buy again the next month"
Subtitle: "Holiday cohorts return least (Dec 2010: 9%, Nov 2011: 14%) · not filtered by customer type"
Rows cohort_month (filter: exclude 2009-12 = left-censored), Columns month_number 1–12, Values Retention %, background color scale

**Action groups bar** — Title: "Retain: 33% of customers, 81% of revenue — Grow holds 14% of future value"
Subtitle: "Win-back: 8% of past revenue but only 3% of predicted CLV = value at risk"
| group | % customers | % net revenue | % CLV 12m | color |
|---|---|---|---|---|
| 1 Retain | 33.1% | 81.2% | 78.2% | #2E7D32 |
| 2 Win-back | 6.9% | 7.7% | 3.1% | #EF6C00 |
| 3 Grow | 26.8% | 5.9% | 13.8% | #1565C0 |
| 4 Low-cost | 33.2% | 5.2% | 4.8% | #9E9E9E |
Filter: action_group not in (0 No CLV, 9 Excluded)

## All measures (paste in DAX query view → Run → Update model with changes)
```DAX
DEFINE
    MEASURE fct_sales_daily[Net Revenue]       = SUM ( fct_sales_daily[net_revenue] )
    MEASURE fct_sales_daily[Gross Sales]       = SUM ( fct_sales_daily[gross_sales] )
    MEASURE fct_sales_daily[Cancelled Amount]  = SUM ( fct_sales_daily[cancellations] )
    MEASURE fct_sales_daily[Cancellation Rate] = DIVIDE ( -[Cancelled Amount], [Gross Sales] )
    MEASURE fct_sales_daily[Total Orders]      = SUM ( fct_sales_daily[orders] )
    MEASURE fct_sales_daily[AOV]               = DIVIDE ( [Gross Sales], [Total Orders] )
    MEASURE fct_sales_daily[Customers]         = DISTINCTCOUNTNOBLANK ( fct_sales_daily[customer_id] )
    MEASURE fct_sales_daily[Net Revenue PY]    = CALCULATE ( [Net Revenue], SAMEPERIODLASTYEAR ( dim_date[Date] ) )
    MEASURE fct_sales_daily[Net Revenue YoY %] = DIVIDE ( [Net Revenue] - [Net Revenue PY], [Net Revenue PY] )
    MEASURE dim_customer[CLV 12m]       = SUM ( dim_customer[clv_12m] )
    MEASURE dim_customer[% Customers]   = DIVIDE ( [Customers],   CALCULATE ( [Customers],   ALLSELECTED ( dim_customer[action_group] ) ) )
    MEASURE dim_customer[% Net Revenue] = DIVIDE ( [Net Revenue], CALCULATE ( [Net Revenue], ALLSELECTED ( dim_customer[action_group] ) ) )
    MEASURE dim_customer[% CLV 12m]     = DIVIDE ( [CLV 12m],     CALCULATE ( [CLV 12m],     ALLSELECTED ( dim_customer[action_group] ) ) )
    MEASURE cohort_retention[Retention %]  = DIVIDE ( SUM ( cohort_retention[active_customers] ), SUM ( cohort_retention[cohort_size] ) )
    MEASURE cohort_retention[Retention M1] = CALCULATE ( [Retention %], cohort_retention[month_number] = 1 )
EVALUATE
ROW ( "Net Revenue", [Net Revenue], "Customers", [Customers], "Cancellation Rate", [Cancellation Rate],
      "Total Orders", [Total Orders], "AOV", [AOV], "CLV 12m", [CLV 12m], "Retention M1", [Retention M1] )
```
Expected: 18,927,382 · 5,875 · 0.0365 · 39,516 · 497.11 · 8,144,866 · 0.230

## ✅ Final measure setup — ALL 15 measures in `fct_sales_daily` (as built)
Net Revenue · Gross Sales · Cancelled Amount · Cancellation Rate · Total Orders · AOV · Customers · Net Revenue PY · Net Revenue YoY % · CLV 12m · % Customers · % Net Revenue · % CLV 12m · Retention % · Retention M1
- `% Customers / % Net Revenue / % CLV 12m` ต้องใช้ **ALLSELECTED** (REMOVEFILTERS → Retain 70% แทน 81%)
- Home table = ที่เก็บเท่านั้น ไม่มีผลกับการคำนวณ · ชื่อ measure ต้องไม่ซ้ำทั้ง model
