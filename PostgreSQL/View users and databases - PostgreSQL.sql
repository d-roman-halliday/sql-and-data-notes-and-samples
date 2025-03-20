-------------------------------------------------------------------------------
-- For server admin notes
-- https://wiki.roman-halliday.com/doku.php?id=server_configuration:postgres
-------------------------------------------------------------------------------
-- How to List All Users in PostgreSQL (built in command)
-------------------------------------------------------------------------------
\du

-------------------------------------------------------------------------------
-- Users (plus metadata) from SQL
-------------------------------------------------------------------------------
SELECT usename AS role_name,
       CASE WHEN usesuper AND usecreatedb THEN CAST('superuser, create database' AS pg_catalog.text)
            WHEN usesuper                 THEN CAST('superuser' AS pg_catalog.text)
            WHEN usecreatedb              THEN CAST('create database' AS pg_catalog.text)
                                          ELSE CAST('' AS pg_catalog.text)
        END role_attributes
  FROM pg_catalog.pg_user
 ORDER BY role_name desc
;

-------------------------------------------------------------------------------
-- View Databases
-------------------------------------------------------------------------------
\l


/*
Please note the following commands:

    \list or \l  : list all databases
    \c <db name> : connect to a certain database
    \dt          : list all tables in the current database using your search_path
    \dt *.       : list all tables in the current database regardless your search_path

You will never see tables in other databases, these tables aren't visible. You have to connect to the correct database to see its tables (and other objects).

To switch databases:

\connect database_name or \c database_name
*/

-------------------------------------------------------------------------------
-- EXIT
-------------------------------------------------------------------------------
\q