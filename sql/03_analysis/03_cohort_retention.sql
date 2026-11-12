WITH customer_months AS (           -- ลูกค้าแต่ละคนซื้อเดือนไหนบ้าง (1 แถว/ลูกค้า/เดือน)
    SELECT customer_id, DATE_TRUNC('month', invoice_ts) AS order_month
    FROM fct_sales
    WHERE has_customer AND row_type = 'sale'
    GROUP BY 1, 2
),
cohorts AS (                        -- เดือนแรกที่ซื้อ = cohort
    SELECT customer_id, MIN(order_month) AS cohort_month
    FROM customer_months
    GROUP BY customer_id
),
activity AS (                       -- แต่ละการซื้ออยู่ห่างจากเดือนแรกกี่เดือน
    SELECT
        c.cohort_month,
        m.customer_id,
        (EXTRACT(YEAR FROM m.order_month) - EXTRACT(YEAR FROM c.cohort_month)) * 12
      + (EXTRACT(MONTH FROM m.order_month) - EXTRACT(MONTH FROM c.cohort_month)) AS month_number
    FROM customer_months m
    JOIN cohorts c ON m.customer_id = c.customer_id
)
SELECT
    cohort_month,
    COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 0) AS cohort_size,
    ROUND(100.0 * COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 1)
          / COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 0), 1) AS m1,
    ROUND(100.0 * COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 2)
          / COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 0), 1) AS m2,
    ROUND(100.0 * COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 3)
          / COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 0), 1) AS m3,
    ROUND(100.0 * COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 6)
          / COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 0), 1) AS m6,
    ROUND(100.0 * COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 12)
          / COUNT(DISTINCT customer_id) FILTER (WHERE month_number = 0), 1) AS m12
FROM activity
GROUP BY cohort_month
ORDER BY cohort_month;