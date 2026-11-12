SELECT
    invoice,
    invoice_ts,
    customer_id,
    stock_code,
    description,
    quantity,
    unit_price,
    line_amount,
    row_type
FROM stg_transactions
WHERE invoice IN ('581483', 'C581484', '541431', 'C541433')
ORDER BY invoice_ts;