-- Percentile ของจำนวนชิ้นต่อออร์เดอร์
SELECT
    percentile_cont(0.50) WITHIN GROUP (ORDER BY avg_units_per_order) AS p50,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY avg_units_per_order) AS p75,
    percentile_cont(0.90) WITHIN GROUP (ORDER BY avg_units_per_order) AS p90,
    percentile_cont(0.95) WITHIN GROUP (ORDER BY avg_units_per_order) AS p95,
    percentile_cont(0.99) WITHIN GROUP (ORDER BY avg_units_per_order) AS p99,
    MAX(avg_units_per_order)                                          AS max_units
FROM mart_customer_base
WHERE frequency > 0;

-- ถ้าตั้งเส้นแบ่งที่ค่าต่างๆ จะมีลูกค้ากี่คน และยอดกี่ %
SELECT
    CASE
        WHEN avg_units_per_order >= 1000 THEN '1) 1000+'
        WHEN avg_units_per_order >= 500  THEN '2) 500-999'
        WHEN avg_units_per_order >= 250  THEN '3) 250-499'
        WHEN avg_units_per_order >= 100  THEN '4) 100-249'
        ELSE                                  '5) <100'
    END                                                            AS units_bucket,
    COUNT(*)                                                       AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)             AS pct_customers,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1)   AS pct_revenue
FROM mart_customer_base
WHERE frequency > 0
GROUP BY 1
ORDER BY 1;