-------------------------------------------------------------------------------
-- How to List All Users in PostgreSQL (built in command)
-------------------------------------------------------------------------------
\du

-------------------------------------------------------------------------------
-- List Databases
-------------------------------------------------------------------------------
\l

-------------------------------------------------------------------------------
-- List Tables & Schemas (by table size)
-------------------------------------------------------------------------------
SELECT table_schema,
       table_name,
	   table_type,
       pg_relation_size('"'||table_schema||'"."'||table_name||'"')
  FROM information_schema.tables
 WHERE table_schema NOT IN ('information_schema','pg_catalog')
 ORDER BY 4
;

WITH table_data AS (
SELECT *,
       pg_relation_size('"'||table_schema||'"."'||table_name||'"') AS table_size
  FROM information_schema.tables
)
SELECT table_schema,
       table_name,
	   table_type,
	   table_size,
	   pg_size_pretty(table_size) AS table_size_pretty
  FROM table_data
 ORDER BY table_size
;

-------------------------------------------------------------------------------
-- Describe table
-------------------------------------------------------------------------------
\d
\d+
