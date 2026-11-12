-- FACT: ยอดขายรายวันต่อลูกค้า
COPY (
    SELECT
        CAST(invoice_ts AS DATE)                                              AS order_date,
        customer_id,                                                          -- NULL = guest
        COUNT(DISTINCT invoice) FILTER (WHERE row_type = 'sale')              AS orders,
        COALESCE(SUM(line_amount) FILTER (WHERE row_type = 'sale'), 0)         AS gross_sales,
        COALESCE(SUM(line_amount) FILTER (WHERE row_type = 'cancellation'), 0) AS cancellations,
        SUM(line_amount)                                                      AS net_revenue
    FROM fct_sales
    GROUP BY ALL
) TO 'E:/Data_Analytic/Online Retail II/data/marts/powerbi/fct_sales_daily.parquet' (FORMAT parquet);

-- DIM: ข้อมูลลูกค้า (1 แถว = ลูกค้า 1 คน)
COPY (
    SELECT
        b.customer_id,
        b.country,
        CAST(DATE_TRUNC('month', b.first_purchase_ts) AS DATE)                AS cohort_month,
        CASE WHEN b.avg_units_per_order >= 500 THEN 'wholesale' ELSE 'retail' END AS customer_type,
        COALESCE(a.segment, '8 Excluded')                                     AS segment,
        COALESCE(a.action_group, '9 Excluded')                                AS action_group,
        b.recency_days,
        b.frequency,
        b.monetary,
        a.p_alive,
        a.clv_12m
    FROM mart_customer_base b
    LEFT JOIN mart_customer_action a ON a.customer_id = b.customer_id
) TO 'E:/Data_Analytic/Online Retail II/data/marts/powerbi/dim_customer.parquet' (FORMAT parquet);

-- COHORT: แบบแนวยาว (long format)
COPY (
    WITH customer_months AS (
        SELECT customer_id, DATE_TRUNC('month', invoice_ts) AS order_month
        FROM fct_sales
        WHERE has_customer AND row_type = 'sale'
        GROUP BY 1, 2
    ),
    cohorts AS (
        SELECT customer_id, MIN(order_month) AS cohort_month
        FROM customer_months
        GROUP BY customer_id
    ),
    counts AS (
        SELECT
            c.cohort_month,
            date_diff('month', c.cohort_month, m.order_month) AS month_number,
            COUNT(DISTINCT m.customer_id)                     AS active_customers
        FROM customer_months m
        JOIN cohorts c ON c.customer_id = m.customer_id
        GROUP BY 1, 2
    )
    SELECT
        CAST(cohort_month AS DATE) AS cohort_month,
        month_number,
        active_customers,
        MAX(CASE WHEN month_number = 0 THEN active_customers END)
            OVER (PARTITION BY cohort_month)                  AS cohort_size
    FROM counts
) TO 'E:/Data_Analytic/Online Retail II/data/marts/powerbi/cohort_retention.parquet' (FORMAT parquet);

-- ตรวจความถูกต้องก่อนส่งให้ Power BI
SELECT
    (SELECT SUM(line_amount) FROM fct_sales)                                   AS net_source,
    (SELECT SUM(net_revenue)
     FROM 'E:/Data_Analytic/Online Retail II/data/marts/powerbi/fct_sales_daily.parquet') AS net_export,
    (SELECT COUNT(DISTINCT f.customer_id)
     FROM 'E:/Data_Analytic/Online Retail II/data/marts/powerbi/fct_sales_daily.parquet' f
     WHERE f.customer_id IS NOT NULL
       AND f.customer_id NOT IN (
           SELECT customer_id
           FROM 'E:/Data_Analytic/Online Retail II/data/marts/powerbi/dim_customer.parquet')) AS orphan_customers;