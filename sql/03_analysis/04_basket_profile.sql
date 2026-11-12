-- basket lines: 1 แถว = สินค้า 1 รายการใน 1 ใบเสร็จ (ไม่สนจำนวนชิ้น)
CREATE OR REPLACE TABLE basket_lines AS
WITH product_names AS (            -- รหัสสินค้าเดียวกันมีหลายชื่อ → ใช้ชื่อที่พบบ่อยที่สุด
    SELECT stock_code, mode(description) AS product_name
    FROM fct_sales
    WHERE row_type = 'sale'
    GROUP BY stock_code
)
SELECT DISTINCT
    s.invoice,
    s.stock_code,
    p.product_name,
    CASE
        WHEN b.customer_id IS NULL           THEN 'guest'
        WHEN b.avg_units_per_order >= 500    THEN 'wholesale'
        ELSE                                      'retail'
    END AS customer_type
FROM fct_sales s
JOIN product_names p ON p.stock_code = s.stock_code
LEFT JOIN mart_customer_base b ON b.customer_id = s.customer_id
WHERE s.row_type = 'sale';

-- ขนาดตะกร้า (จำนวนสินค้าไม่ซ้ำต่อใบเสร็จ)
WITH sizes AS (
    SELECT invoice, customer_type, COUNT(*) AS n_items
    FROM basket_lines
    GROUP BY invoice, customer_type
)
SELECT
    customer_type,
    COUNT(*)                                AS invoices,
    ROUND(AVG(n_items), 1)                  AS avg_items,
    median(n_items)                         AS median_items,
    COUNT(*) FILTER (WHERE n_items = 1)     AS single_item_invoices,
    MAX(n_items)                            AS max_items
FROM sizes
GROUP BY customer_type;

-- สินค้า 10 อันดับแรก: อยู่ในกี่ % ของใบเสร็จ
SELECT
    stock_code,
    product_name,
    COUNT(DISTINCT invoice) AS invoices,
    ROUND(100.0 * COUNT(DISTINCT invoice)
          / (SELECT COUNT(DISTINCT invoice) FROM basket_lines), 2) AS pct_invoices
FROM basket_lines
GROUP BY stock_code, product_name
ORDER BY invoices DESC
LIMIT 10;

-- ถ้าตั้งเกณฑ์ขั้นต่ำ จะเหลือสินค้ากี่รายการ
WITH p AS (
    SELECT stock_code, COUNT(DISTINCT invoice) AS n
    FROM basket_lines
    GROUP BY stock_code
),
t AS (SELECT COUNT(DISTINCT invoice) AS total FROM basket_lines)
SELECT
    COUNT(*)                                       AS all_products,
    COUNT(*) FILTER (WHERE n >= 0.005 * t.total)   AS products_ge_0_5pct,
    COUNT(*) FILTER (WHERE n >= 0.01  * t.total)   AS products_ge_1pct,
    COUNT(*) FILTER (WHERE n >= 0.02  * t.total)   AS products_ge_2pct
FROM p, t;

-- ส่งให้ Python
COPY basket_lines
TO 'E:/Data_Analytic/Online Retail II/data/marts/basket_lines.parquet' (FORMAT parquet);