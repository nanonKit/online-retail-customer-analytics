-- สรุปพฤติกรรมลูกค้า
CREATE OR REPLACE TABLE mart_customer_base AS
SELECT
    customer_id,
    mode(country)                                                  AS country,
    MIN(invoice_ts) FILTER (WHERE row_type = 'sale')               AS first_purchase_ts,
    MAX(invoice_ts) FILTER (WHERE row_type = 'sale')               AS last_purchase_ts,
    DATE '2011-12-10'
      - CAST(MAX(invoice_ts) FILTER (WHERE row_type = 'sale') AS DATE) AS recency_days,
    COUNT(DISTINCT invoice) FILTER (WHERE row_type = 'sale')       AS frequency,
    SUM(line_amount)                                               AS monetary,
    SUM(quantity) FILTER (WHERE row_type = 'sale') * 1.0
      / COUNT(DISTINCT invoice) FILTER (WHERE row_type = 'sale')   AS avg_units_per_order,
    SUM(line_amount) FILTER (WHERE row_type = 'sale')
      / COUNT(DISTINCT invoice) FILTER (WHERE row_type = 'sale')   AS avg_order_value
FROM fct_sales
WHERE has_customer
GROUP BY customer_id;

-- ตรวจ
SELECT
    COUNT(*)                                   AS customers,
    COUNT(*) FILTER (WHERE frequency = 0)      AS only_cancellations,
    COUNT(*) FILTER (WHERE monetary <= 0)      AS non_positive_monetary,
    SUM(monetary)                              AS total_monetary
FROM mart_customer_base;

SELECT 
	AVG(avg_units_per_order)		AS mean,
	MEDIAN(avg_units_per_order)		AS median,
	skewness(avg_units_per_order)	AS skewness
FROM mart_customer_base
WHERE frequency > 0;