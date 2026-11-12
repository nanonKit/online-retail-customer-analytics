-- cleaning + แปลง type
CREATE OR REPLACE TABLE stg_transactions AS
WITH no_overlap AS (                                   -- Decision #1 ตัดชุดซ้อน
    SELECT *
    FROM raw_transactions
    WHERE NOT (source_sheet = 'Year 2009-2010'
               AND excel_to_ts(InvoiceDate) >= TIMESTAMP '2010-12-01')
),
deduped AS (                                           -- Decision #2 ลบแถวซ้ำ
    SELECT DISTINCT * FROM no_overlap
),
typed AS (                                             -- Decision #10 #11 #12
    SELECT
        TRIM(Invoice)                       AS invoice,
        UPPER(TRIM(StockCode))              AS stock_code,
        TRIM(Description)                   AS description,
        CAST(Quantity AS INTEGER)           AS quantity,
        excel_to_ts(InvoiceDate)            AS invoice_ts,
        CAST(Price AS DECIMAL(18, 4))       AS unit_price,
        NULLIF(TRIM("Customer ID"), '')     AS customer_id,
        TRIM(Country)                       AS country,
        source_sheet
    FROM deduped
)
SELECT
    *,
    quantity * unit_price AS line_amount,
    CASE                                               -- Decision #3–#8
        WHEN invoice LIKE 'A%' THEN 'adjustment'
        WHEN stock_code IN ('POST', 'DOT', 'C2', 'C3', 'M', 'ADJUST', 'ADJUST2', 'D', 'S',
                            'BANK CHARGES', 'AMAZONFEE', 'CRUK', 'B',
                            'TEST001', 'TEST002', 'DCGS0068')
          OR starts_with(stock_code, 'GIFT_0001_') THEN 'non_product'
        WHEN invoice LIKE 'C%' THEN 'cancellation'
        WHEN quantity < 0      THEN 'inventory_adjustment'
        WHEN unit_price = 0    THEN 'zero_price'
        ELSE 'sale'
    END AS row_type,
    invoice LIKE 'C%'       AS is_cancellation,
    customer_id IS NOT NULL AS has_customer
FROM typed;