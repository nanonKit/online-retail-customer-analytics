-- import CLV
CREATE OR REPLACE TABLE stg_customer_clv AS
SELECT *
FROM 'E:/Data_Analytic/Online Retail II/data/marts/customer_clv.parquet';

DESCRIBE stg_customer_clv;

-- join checkig: ลูกค้าใน RFM มีผล CLV ครบทุกคนไหม
SELECT
    COUNT(*)               AS rfm_customers,
    COUNT(c.customer_id)   AS matched_clv,
    COUNT(*) - COUNT(c.customer_id) AS missing_clv
FROM mart_customer_rfm r
LEFT JOIN stg_customer_clv c ON c.customer_id = r.customer_id;

-- distribution of P(alive) และ CLV แยกตามประเภทลูกค้า
SELECT
    r.customer_type,
    COUNT(*)                                          AS customers,
    quantile_cont(c.p_alive, [0.10, 0.25, 0.50, 0.75]) AS p_alive_q,
    quantile_cont(c.clv_12m, [0.50, 0.80, 0.95])       AS clv_q
FROM mart_customer_rfm r
JOIN stg_customer_clv c ON c.customer_id = r.customer_id
GROUP BY ALL;

-- ถ้าใช้เกณฑ์ P(alive) แต่ละค่า จะมีลูกค้าอยู่ใต้เกณฑ์กี่ %
SELECT
    r.customer_type,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE c.p_alive < 0.3) / COUNT(*), 1) AS pct_below_030,
    ROUND(100.0 * COUNT(*) FILTER (WHERE c.p_alive < 0.5) / COUNT(*), 1) AS pct_below_050,
    ROUND(100.0 * COUNT(*) FILTER (WHERE c.p_alive < 0.7) / COUNT(*), 1) AS pct_below_070,
    -- เทียบกับ RFM: Hibernating + At Risk ควรมี P(alive) ต่ำ ถ้าไม่ใช่ แปลว่าสองวิธีให้ผลขัดกัน
        ROUND(AVG(c.p_alive) FILTER (WHERE r.segment IN ('6 At Risk', '7 Hibernating')), 3) AS p_alive_dormant,
        ROUND(AVG(c.p_alive) FILTER (WHERE r.segment = '1 Champions'), 3)                   AS p_alive_champions
FROM mart_customer_rfm r
JOIN stg_customer_clv c ON c.customer_id = r.customer_id
GROUP BY ALL;

-- action group (1 แถว = ลูกค้า 1 คน)
CREATE OR REPLACE TABLE mart_customer_action AS
SELECT
    r.customer_id, r.customer_type, r.segment,
    r.recency_days, r.frequency, r.monetary, r.r_score, r.m_score,
    c.p_alive, c.clv_12m,
    CASE
        WHEN c.customer_id IS NULL             THEN '0 No CLV'
        WHEN r.m_score >= 4 AND r.r_score >= 3 THEN '1 Retain'
        WHEN r.m_score >= 4                    THEN '2 Win-back'
        WHEN r.r_score >= 3                    THEN '3 Grow'
        ELSE                                        '4 Low-cost'
    END AS action_group
FROM mart_customer_rfm r
LEFT JOIN stg_customer_clv c ON c.customer_id = r.customer_id;

-- สรุปแต่ละกลุ่ม
SELECT
    customer_type,
    action_group,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*)      / SUM(COUNT(*))      OVER (PARTITION BY customer_type), 1) AS pct_customers,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (PARTITION BY customer_type), 1) AS pct_hist_revenue,
    ROUND(100.0 * SUM(clv_12m)  / SUM(SUM(clv_12m))  OVER (PARTITION BY customer_type), 1) AS pct_clv_12m,
    ROUND(median(recency_days)) AS med_recency_days
FROM mart_customer_action
GROUP BY customer_type, action_group
ORDER BY customer_type, action_group;

-- Win-back budget simulation: ส่งแคมเปญให้กี่กลุ่มถึงคุ้ม
WITH params AS (
    SELECT
        0.10 AS uplift_rate,       -- ลูกค้าที่กลับมาเพราะแคมเปญ (สมมติ ต้องวัดจริงด้วย A/B test)
        0.30 AS gross_margin,      -- กำไรขั้นต้นต่อยอดขาย (สมมติ)
        5.00 AS cost_per_customer  -- £ ต่อคน (voucher + ads)
),
ranked AS (
    SELECT
        customer_type,
        monetary / frequency AS aov,
        NTILE(10) OVER (PARTITION BY customer_type ORDER BY clv_12m DESC) AS clv_decile
    FROM mart_customer_action
    WHERE action_group = '2 Win-back'
)
SELECT
    r.customer_type,
    r.clv_decile,
    COUNT(*)                                                     AS customers,
    ROUND(AVG(r.aov))                                            AS avg_aov,
    ROUND(SUM(r.aov) * p.uplift_rate * p.gross_margin
          - COUNT(*) * p.cost_per_customer)                      AS net_profit,
    ROUND(SUM(SUM(r.aov) * p.uplift_rate * p.gross_margin
              - COUNT(*) * p.cost_per_customer)
          OVER (PARTITION BY r.customer_type ORDER BY r.clv_decile)) AS cum_net_profit
FROM ranked r
CROSS JOIN params p
GROUP BY r.customer_type, r.clv_decile, p.uplift_rate, p.gross_margin, p.cost_per_customer
ORDER BY r.customer_type, r.clv_decile;