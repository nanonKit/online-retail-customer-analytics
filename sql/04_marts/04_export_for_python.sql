COPY (
    WITH sales AS (
        SELECT *
        FROM fct_sales s
        WHERE s.row_type = 'sale'
          AND s.has_customer
          AND s.customer_id IN (SELECT customer_id FROM mart_customer_rfm)
          AND NOT EXISTS (                       -- ตัดรายการที่ถูกยกเลิกภายหลัง
              SELECT 1
              FROM fct_sales c
              WHERE c.row_type    = 'cancellation'
                AND c.customer_id = s.customer_id
                AND c.stock_code  = s.stock_code
                AND -c.quantity   = s.quantity
                AND c.unit_price  = s.unit_price
                AND c.invoice_ts >= s.invoice_ts
          )
    )
    SELECT customer_id, CAST(invoice_ts AS DATE) AS purchase_date, SUM(line_amount) AS amount
    FROM sales
    GROUP BY customer_id, CAST(invoice_ts AS DATE)
) TO 'E:/Data_Analytic/Online Retail II/data/marts/clv_daily_transactions.parquet' (FORMAT parquet);