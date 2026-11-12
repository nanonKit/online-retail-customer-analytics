-- นับแต่ละประเภท
WITH typed AS (
    SELECT *,
        TRY_CAST(Quantity AS INTEGER) AS qty_num,
        TRY_CAST(Price AS DOUBLE)     AS price_num
    FROM raw_transactions
),
classified AS (
    SELECT *,
        CASE
            WHEN Invoice LIKE 'A%'                          THEN 'adjustment'
            WHEN Invoice LIKE 'C%'                          THEN 'cancellation'
            WHEN qty_num < 0                                THEN 'inventory_adjustment'
            WHEN price_num = 0                              THEN 'zero_price'
            WHEN NOT regexp_matches(StockCode, '^[0-9]{5}') THEN 'non_product'
            ELSE 'sale'
        END AS row_type
    FROM typed
)
SELECT
    row_type,
    COUNT(*)                                            AS row_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)  AS pct_rows,
    ROUND(SUM(qty_num * price_num), 2)                  AS amount
FROM classified
GROUP BY row_type
ORDER BY row_count DESC;

-- StockCode ที่ไม่ใช่รหัสสินค้า 5 หลัก มีอะไรบ้าง
SELECT
    StockCode,
    ANY_VALUE(Description) AS example_description,
    COUNT(*)               AS row_count
FROM raw_transactions
WHERE NOT regexp_matches(StockCode, '^[0-9]{5}')
GROUP BY StockCode
ORDER BY row_count DESC;