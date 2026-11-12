INSTALL excel;
LOAD excel;

SELECT extension_name, installed, loaded
FROM duckdb_extensions()
WHERE extension_name = 'excel';

SELECT *
FROM read_xlsx('E:\Data_Analytic\Online Retail II\data\raw\online_retail_II.xlsx',
				sheet = 'Year 2009-2010',
				all_varchar = true)
LIMIT 20;

DESCRIBE
SELECT *
FROM read_xlsx('E:\Data_Analytic\Online Retail II\data\raw\online_retail_II.xlsx',
				sheet = 'Year 2009-2010',
				all_varchar = true);