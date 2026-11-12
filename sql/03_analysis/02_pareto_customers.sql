-- ลูกค้า top 20% สร้างยอดขายกี่ %
WITH customer_revenue AS (
    SELECT customer_id, SUM(line_amount) AS net_revenue
    FROM fct_sales
    WHERE has_customer
    GROUP BY customer_id
),
ranked AS (
    SELECT
        customer_id,
        net_revenue,
        NTILE(5) OVER (ORDER BY net_revenue DESC) AS quintile
    FROM customer_revenue
)
SELECT
    quintile,
    COUNT(*)                                                     AS customers,
    SUM(net_revenue)                                             AS revenue,
    ROUND(100.0 * SUM(net_revenue) / SUM(SUM(net_revenue)) OVER (), 2) AS revenue_share_pct
FROM ranked
GROUP BY quintile
ORDER BY quintile;

-- Gini coefficient ของยอดซื้อต่อลูกค้า (เฉพาะลูกค้าที่ยอดเป็นบวก)
WITH customer_revenue AS (
    SELECT customer_id, SUM(line_amount) AS net_revenue
    FROM fct_sales
    WHERE has_customer
    GROUP BY customer_id
),
ordered AS (
    SELECT
        net_revenue,
        ROW_NUMBER() OVER (ORDER BY net_revenue) AS i,
        COUNT(*) OVER ()                         AS n
    FROM customer_revenue
    WHERE net_revenue > 0
)
SELECT ROUND(
    2.0 * SUM(i * net_revenue) / (MAX(n) * SUM(net_revenue)) - (MAX(n) + 1.0) / MAX(n),
3) AS gini
FROM ordered;

-- ลูกค้าที่ยอดสุทธิ ≤ 0
WITH customer_revenue AS (
    SELECT customer_id, SUM(line_amount) AS net_revenue
    FROM fct_sales
    WHERE has_customer
    GROUP BY customer_id
)
SELECT COUNT(*) AS customers_non_positive
FROM customer_revenue
WHERE net_revenue <= 0;