-- ช่วงเวลาของแต่ละ sheet
SELECT
    source_sheet,
    MIN(excel_to_ts(InvoiceDate))  AS first_ts,
    MAX(excel_to_ts(InvoiceDate))  AS last_ts,
    COUNT(*)                       AS row_count,
    COUNT(DISTINCT Invoice)        AS invoice_count
FROM raw_transactions
GROUP BY source_sheet
ORDER BY source_sheet;

-- Invoice ที่อยู่ทั้งสอง sheet ไหม
SELECT COUNT(*) AS invoices_in_both_sheets
FROM (
    SELECT Invoice FROM raw_transactions WHERE source_sheet = 'Year 2009-2010'
    INTERSECT
    SELECT Invoice FROM raw_transactions WHERE source_sheet = 'Year 2010-2011'
);

-- จำนวนแถวช่วงซ้อนใน sheet แรก
SELECT COUNT(*) AS overlap_rows
FROM raw_transactions
WHERE source_sheet = 'Year 2009-2010'
  AND excel_to_ts(InvoiceDate) >= TIMESTAMP '2010-12-01';

-- สองชุดเหมือนกันทุกแถวไหม (ควรได้ 0)
SELECT COUNT(*) AS rows_only_in_sheet1
FROM (
    SELECT * EXCLUDE (source_sheet) FROM raw_transactions
    WHERE source_sheet = 'Year 2009-2010' AND excel_to_ts(InvoiceDate) >= TIMESTAMP '2010-12-01'
    EXCEPT ALL
    SELECT * EXCLUDE (source_sheet) FROM raw_transactions
    WHERE source_sheet = 'Year 2010-2011' AND excel_to_ts(InvoiceDate) < TIMESTAMP '2010-12-10'
);