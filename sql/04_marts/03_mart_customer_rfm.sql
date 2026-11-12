-- ให้คะแนน RFM แยกตาม segment
CREATE OR REPLACE TABLE mart_customer_rfm AS
WITH base AS (
	SELECT 
        *,
        CASE WHEN avg_units_per_order >= 500 THEN 'wholesale' ELSE 'retail' END AS customer_type 
    FROM mart_customer_base
    WHERE frequency > 0 AND monetary > 0
),
scored AS (
    SELECT 
        *,
        NTILE(5) OVER (PARTITION BY customer_type ORDER BY recency_days DESC) AS r_score,
        CASE
            WHEN frequency >= 10 THEN 5 
            WHEN frequency >= 5 THEN 4 
            WHEN frequency >= 3 THEN 2 
            WHEN frequency >= 2 THEN 2
            ELSE 1
        END                                                                 AS f_score,
        NTILE(5) OVER (PARTITION BY customer_type ORDER BY monetary ASC)    AS m_score
    FROM base
)
SELECT 
    *,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 THEN '1 Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN '2 Loyal'
        WHEN r_score >= 4 AND f_score >= 2 THEN '3 New/Promising'
        WHEN r_score >= 3 AND f_score >= 2 THEN '4 Need Attention'
        WHEN r_score >= 2 AND f_score >= 4 THEN '5 Cannot Lose Them'
        WHEN r_score >= 2 AND f_score >= 2 THEN '6 At Risk'
        ELSE                                    '7 Hibernating'
    END AS segment
FROM scored;

-- result
SELECT
    customer_type,
    segment,
    COUNT(*)                                                                                AS customer,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY customer_type), 1)            AS pct_cutomers,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (PARTITION BY customer_type), 1)  AS pct_revenue,
    ROUND(AVG(recency_days))                                                                AS avg_recency_days,
    ROUND(AVG(frequency), 1)                                                                AS avg_frequency
    FROM mart_customer_rfm 
    GROUP BY customer_type, segment
    ORDER BY customer_type, segment;
    