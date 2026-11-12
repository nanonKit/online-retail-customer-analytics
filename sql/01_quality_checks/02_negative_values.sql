SELECT 
	MIN(TRY_CAST(Quantity AS INTEGER)) AS min_qty,
	MAX(TRY_CAST(Quantity AS INTEGER)) AS max_qty,
	MIN(TRY_CAST(Price AS DOUBLE)) 	   AS min_qty,
	MAX(TRY_CAST(Price AS DOUBLE))     AS max_qty
FROM raw_transactions;

SELECT *
FROM raw_transactions
WHERE TRY_CAST(Price AS DOUBLE) < 0;

-- 5 แถวที่ Quantity มากที่สุด
SELECT * FROM raw_transactions
ORDER BY TRY_CAST(Quantity AS INTEGER) DESC
LIMIT 5;
-- 5 แถวที่ Quantity น้อยที่สุด
SELECT * FROM raw_transactions
ORDER BY TRY_CAST(Quantity AS INTEGER) ASC
LIMIT 5;