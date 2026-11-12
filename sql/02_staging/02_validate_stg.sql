-- จำนวนแถว
SELECT COUNT(*) AS row_count FROM stg_transactions;

-- แปลง type แล้วไม่มีค่าหาย
SELECT
    COUNT(*) FILTER (WHERE invoice_ts IS NULL) AS null_ts,
    COUNT(*) FILTER (WHERE quantity   IS NULL) AS null_qty,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS null_price
FROM stg_transactions;

-- ช่วงเวลา
SELECT MIN(invoice_ts) AS first_ts, MAX(invoice_ts) AS last_ts FROM stg_transactions;

-- แต่ละประเภทหลัง clean
SELECT row_type, COUNT(*) AS row_count, SUM(line_amount) AS amount
FROM stg_transactions
GROUP BY row_type
ORDER BY row_count DESC;

-- % แถวที่ไม่มีลูกค้า
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE NOT has_customer) / COUNT(*), 2) AS pct_no_customer
FROM stg_transactions;