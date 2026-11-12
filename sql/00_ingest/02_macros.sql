/*
Purpose : Reusable macros (run after 01_load_raw.sql, before 02_staging)
excel_to_ts: Excel serial date -> TIMESTAMP (day 0 = 1899-12-30, serial 25569 = 1970-01-01)
*/
CREATE OR REPLACE MACRO excel_to_ts(x) AS
    epoch_ms(CAST(ROUND((CAST(x AS DOUBLE) - 25569) * 86400) AS BIGINT) * 1000);
