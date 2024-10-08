--------------------------------------------------------------------------------
-- A report for checking disk space/tablespace usage
-- See: https://datablog.roman-halliday.com/index.php/2021/08/14/checking-tablespace-usage-availability-in-oracle/
--------------------------------------------------------------------------------
WITH df AS (
SELECT tablespace_name,
       ROUND(SUM(bytes) / 1048576) TotalSpace
  FROM dba_data_files
 GROUP BY tablespace_name
), tu AS (
SELECT round(SUM(bytes)/(1024*1024)) totalusedspace,
       tablespace_name
  FROM dba_segments
 GROUP BY tablespace_name
)
SELECT df.tablespace_name                                                       "Tablespace",
       totalusedspace                                                           "Used MB",
       (df.totalspace - tu.totalusedspace)                                      "Free MB",
       df.totalspace                                                            "Total MB",
       CAST( totalusedspace/1024 AS NUMBER(20,2))                               "Used GB",
       CAST((df.totalspace/1024 - tu.totalusedspace/1024) AS NUMBER(20,2))      "Free GB",
       CAST( df.totalspace/1024 AS NUMBER(20,2))                                "Total GB",
       round(100 * ( (df.totalspace - tu.totalusedspace)/ df.totalspace))       "Pct. Free",
       100 - round(100 * ( (df.totalspace - tu.totalusedspace)/ df.totalspace)) "Pct. Used"
  FROM df
    INNER JOIN tu
       ON df.tablespace_name = tu.tablespace_name
 ORDER BY df.tablespace_name
;