-- ยอดขายสินค้าจริง + ยกเลิก
CREATE OR REPLACE TABLE fct_sales AS
SELECT *
FROM stg_transactions
WHERE row_type IN ('sale', 'cancellation');

-- ยอดขายสุทธิ
SELECT COUNT(*) AS row_count, SUM(line_amount) AS net_revenue FROM fct_sales;