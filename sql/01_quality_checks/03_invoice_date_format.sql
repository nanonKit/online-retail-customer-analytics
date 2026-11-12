SELECT 
	InvoiceDate,
	epoch_ms(
		CAST(ROUND((CAST(InvoiceDate AS DOUBLE) - 25569) * 86400) AS BIGINT) * 1000) AS invoice_ts
FROM raw_transactions
LIMIT 10;