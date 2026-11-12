-- 7.1 นับแถวซ้ำ (หลังตัดช่วงซ้อนของ sheet 1 แล้ว)
WITH no_overlap AS (
    SELECT * EXCLUDE (source_sheet)
    FROM raw_transactions
    WHERE NOT (source_sheet = 'Year 2009-2010'
               AND excel_to_ts(InvoiceDate) >= TIMESTAMP '2010-12-01')
)
SELECT
    COUNT(*)                                          AS total_rows,
    (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM no_overlap)) AS distinct_rows,
    COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM no_overlap)) AS duplicate_rows
FROM no_overlap;

-- 7.2 ตัวอย่างแถวที่ซ้ำ
WITH no_overlap AS (
    SELECT * EXCLUDE (source_sheet)
    FROM raw_transactions
    WHERE NOT (source_sheet = 'Year 2009-2010'
               AND excel_to_ts(InvoiceDate) >= TIMESTAMP '2010-12-01')
)
SELECT *, COUNT(*) AS copies
FROM no_overlap
GROUP BY ALL
HAVING COUNT(*) > 1
ORDER BY copies DESC
LIMIT 10;

-- 7.3 มี Invoice ไหนที่แต่ละแถวมีเวลาต่างกันไหม
SELECT COUNT(*) AS invoices_with_multiple_times
FROM (
    SELECT Invoice
    FROM raw_transactions
    GROUP BY Invoice
    HAVING COUNT(DISTINCT InvoiceDate) > 1
);