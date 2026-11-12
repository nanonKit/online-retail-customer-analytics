CREATE OR REPLACE TABLE raw_transactions AS
SELECT *, 'Year 2009-2010' AS source_sheet
FROM read_xlsx('E:/Data_Analytic/Online Retail II/data/raw/online_retail_II.xlsx',
               sheet = 'Year 2009-2010', all_varchar = true)           
               
UNION ALL

SELECT *, 'Year 2010-2011' AS source_sheet
FROM read_xlsx('E:/Data_Analytic/Online Retail II/data/raw/online_retail_II.xlsx',
               sheet = 'Year 2010-2011', all_varchar = true);

SHOW TABLES;

--checking
SELECT source_sheet, count(*) AS row_count
FROM raw_transactions
GROUP BY source_sheet;
               
               