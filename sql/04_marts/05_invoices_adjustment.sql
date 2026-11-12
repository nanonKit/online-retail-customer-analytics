-- รายการซื้อที่มีรายการยกเลิกคู่กัน (ลูกค้า สินค้า จำนวน ราคา ตรงกัน และยกเลิกทีหลัง)
SELECT COUNT(*) AS matched_lines, ROUND(SUM(s.line_amount), 2) AS matched_amount
FROM fct_sales s
WHERE s.row_type = 'sale'
  AND s.has_customer
  AND EXISTS (
      SELECT 1
      FROM fct_sales c
      WHERE c.row_type    = 'cancellation'
        AND c.customer_id = s.customer_id
        AND c.stock_code  = s.stock_code
        AND -c.quantity   = s.quantity
        AND c.unit_price  = s.unit_price
        AND c.invoice_ts >= s.invoice_ts
  );