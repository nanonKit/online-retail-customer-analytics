-- ยอดขายแต่ละเดือน ฤดูกาล growth
SELECT
    DATE_TRUNC('month', invoice_ts)                                AS month,
    SUM(line_amount) FILTER (WHERE row_type = 'sale')              AS gross_sales,
    SUM(line_amount) FILTER (WHERE row_type = 'cancellation')      AS cancellations,
    SUM(line_amount)                                               AS net_revenue,
    COUNT(DISTINCT invoice) FILTER (WHERE row_type = 'sale')       AS orders,
    COUNT(DISTINCT customer_id) FILTER (WHERE row_type = 'sale')   AS customers,
    ROUND(
        SUM(line_amount) FILTER (WHERE row_type = 'sale')
        / COUNT(DISTINCT invoice) FILTER (WHERE row_type = 'sale'), 2
    )                                                              AS avg_order_value,
    DATE_TRUNC('month', invoice_ts) = DATE '2011-12-01'            AS is_partial_month
FROM fct_sales
GROUP BY 1
ORDER BY 1;

-- ยอด 1–9 ธ.ค. ของแต่ละปี (เทียบช่วงเวลาเท่ากัน)
SELECT
    EXTRACT(YEAR FROM invoice_ts) AS year,
    SUM(line_amount)              AS net_revenue_dec_1_to_9
FROM fct_sales
WHERE EXTRACT(MONTH FROM invoice_ts) = 12
  AND EXTRACT(DAY FROM invoice_ts) <= 9
GROUP BY 1
ORDER BY 1;