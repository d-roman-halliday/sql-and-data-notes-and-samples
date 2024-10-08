--------------------------------------------------------------------------------
-- Note: For this to work in sqldeveloper (other tools configure output differently)
--       Before calling the proc one needs to set:
-- SET SERVEROUTPUT ON
 
-- Sample (everything):
-- CALL dm_code_creation.script_add_dates('my_test_table');
-- CALL dm_code_creation.script_merge_statement('my_test_table');
-- CALL dm_code_creation.script_insert_statement('my_test_table');
--
-- Sample (sqldeveloper):
-- EXECUTE dm_code_creation.script_add_dates('my_test_table');
-- EXECUTE dm_code_creation.script_merge_statement('my_test_table');
-- EXECUTE dm_code_creation.script_insert_statement('my_test_table');
-- https://stackoverflow.com/questions/20571647/oracle-sql-stored-procedures-call-vs-execute
--------------------------------------------------------------------------------
-- Package
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE dm_code_creation
AS
  PROCEDURE script_add_dates
           (target_table IN VARCHAR2,
            target_user  IN VARCHAR2 DEFAULT NULL
           );
  PROCEDURE script_merge_statement
           (target_table IN VARCHAR2,
            target_user  IN VARCHAR2 DEFAULT NULL
           );
  PROCEDURE script_insert_statement
           (target_table IN VARCHAR2,
            target_user  IN VARCHAR2 DEFAULT NULL
           );
END;
/

--------------------------------------------------------------------------------
-- Body
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY dm_code_creation
AS
  FUNCTION manage_user
          (given_user IN VARCHAR2
          ) RETURN VARCHAR2
  IS
    return_value VARCHAR2(30);
  BEGIN
    IF given_user IS NOT NULL THEN
      BEGIN
        return_value := given_user;
      END;
    ELSE
      BEGIN
        return_value :=  USER;
      END;
    END IF;
   
    RETURN return_value;
  END;
 
  FUNCTION trim_name
          (table_name IN VARCHAR2
          ) RETURN VARCHAR2
  IS
    return_value VARCHAR2(30);
  BEGIN
    IF LENGTH(table_name) > 27 THEN
      BEGIN
        return_value := SUBSTR(table_name, 1, 27);
      END;
    ELSE
      BEGIN
        return_value :=  table_name;
      END;
    END IF;
   
    RETURN return_value;
  END;
 
  FUNCTION get_merge_where_list
          (target_table IN VARCHAR2,
           managed_user IN VARCHAR2
          ) RETURN SYS_REFCURSOR
  IS
    c SYS_REFCURSOR;
  BEGIN
    OPEN c FOR
    WITH pk_info AS (
    SELECT constraint_name,
           owner,
           acc.table_name,
           column_name
      FROM all_cons_columns acc
        INNER JOIN all_constraints ac USING (constraint_name,owner)
     WHERE ac.constraint_type = 'P'
    ), last_col AS (
    SELECT owner,
           table_name,
           MAX(column_id) max_column_id
      FROM all_tab_columns
      GROUP BY owner,
           table_name
    )
    SELECT LISTAGG(CASE
                       WHEN constraint_name IS NULL
                         THEN 'DECODE(' || 'tgt.' || LOWER(column_name)
                                 || ',' || 'imp.' || LOWER(column_name)
                                 || ',1,0) = 0'
                       ELSE NULL
                   END, ' OR ') WITHIN GROUP (ORDER BY column_id) merge_where_list
      FROM all_tab_columns
        INNER JOIN last_col USING(owner, table_name)
         LEFT JOIN pk_info USING(owner, table_name, column_name)
     WHERE UPPER(table_name) = UPPER(get_merge_where_list.target_table)
       AND UPPER(owner)      = UPPER(get_merge_where_list.managed_user)
       AND UPPER(column_name) NOT LIKE UPPER('tracking_data_%') -- This is used where there is a column starting 'tracking_data_' which is used to track created and updated dates
     GROUP BY FLOOR(column_id/10)
     ORDER BY FLOOR(column_id/10)
    ;
     
    RETURN c;
  END;
 
  PROCEDURE script_add_dates
           (target_table IN VARCHAR2,
            target_user  IN VARCHAR2 DEFAULT NULL
           )
  IS
    managed_user VARCHAR2(30);
    compare_stmnt_value VARCHAR2(6000);
    change_check_list SYS_REFCURSOR;
  BEGIN
    ----------------------------------------------------------------------------
    -- Variables
    managed_user := manage_user(target_user);
 
    ----------------------------------------------------------------------------
    -- Output
   
    dbms_output.put_line('--------------------------------------------------------------------------------');
    dbms_output.put_line('-- Add Date Tracking -- ' || LOWER(script_add_dates.managed_user) || '.' || LOWER(script_add_dates.target_table));
    dbms_output.put_line('--------------------------------------------------------------------------------');
   
    ----------------------------------------------------------------------------
    dbms_output.put_line('-- Add Columns');
    dbms_output.put_line('ALTER TABLE ' || LOWER(script_add_dates.managed_user) || '.' || LOWER(script_add_dates.target_table));
    dbms_output.put_line('ADD(tracking_data_date_created DATE DEFAULT SYSDATE NOT NULL,');
    dbms_output.put_line('    tracking_data_date_updated DATE DEFAULT SYSDATE NOT NULL');
    dbms_output.put_line(')');
    dbms_output.put_line(';');
 
    dbms_output.put_line('--INDEX THEM');
    dbms_output.put_line('CREATE');
    dbms_output.put_line(' INDEX ' || trim_name(script_add_dates.target_table) || '_dc');
    dbms_output.put_line('    ON ' || LOWER(script_add_dates.target_table));
    dbms_output.put_line('      (tracking_data_date_created)');
    dbms_output.put_line('       NOLOGGING');
    dbms_output.put_line(';');
 
    dbms_output.put_line('CREATE');
    dbms_output.put_line(' INDEX ' || trim_name(script_add_dates.target_table) || '_du');
    dbms_output.put_line('    ON ' || LOWER(script_add_dates.target_table));
    dbms_output.put_line('      (tracking_data_date_updated)');
    dbms_output.put_line('       NOLOGGING');
    dbms_output.put_line(';');
   
   
    ----------------------------------------------------------------------------
    dbms_output.put_line('');
    dbms_output.put_line('--Create trigger');
  --dbms_output.put_line('CREATE OR REPLACE TRIGGER ' || trim_name(script_add_dates.target_table) || '_bu');
    dbms_output.put_line('CREATE TRIGGER ' || trim_name(script_add_dates.target_table) || '_bu'); --Safer as if a name ends up twice the SQL will work with a replace and we will break things
    dbms_output.put_line('BEFORE UPDATE');
    dbms_output.put_line('   ON ' || script_add_dates.target_table);
    dbms_output.put_line('   FOR EACH ROW');
    dbms_output.put_line('BEGIN');
    ----------------------------------------------------------------------------
    --<PUT IF STATEMENT HERE>
    OPEN change_check_list FOR
      WITH column_values AS (
      SELECT table_name,
             column_id,
             column_name,
             owner,
             CASE column_id WHEN 1 THEN '   IF' ELSE '      OR' END logic_construct,
             ':NEW.' || column_name new_col_name,
             ':OLD.' || column_name old_col_name
             FROM all_tab_columns
      )
      SELECT logic_construct
                || '('
                          || '(' || new_col_name || ' IS NULL AND '     || old_col_name || ' IS NOT NULL' || ')'
                || ' OR ' || '(' || new_col_name || ' IS NOT NULL AND ' || old_col_name || ' IS NULL' || ')'
                || ' OR ' || '(' || new_col_name || '<>'                || old_col_name || ')'
                || ')' compare_stmnt
        FROM column_values
       WHERE UPPER(table_name) = UPPER(script_add_dates.target_table)
         AND UPPER(owner)      = UPPER(script_add_dates.managed_user)
         AND UPPER(column_name) NOT LIKE UPPER('tracking_data_%')
       ORDER BY column_id
      ;
   
      LOOP
        FETCH change_check_list INTO compare_stmnt_value;
        EXIT WHEN change_check_list%NOTFOUND;

        dbms_output.put_line(compare_stmnt_value);
      END LOOP;
    CLOSE change_check_list;
   
    ----------------------------------------------------------------------------
    dbms_output.put_line('   THEN');
    dbms_output.put_line('      :new.tracking_data_date_updated := SYSDATE;');
    dbms_output.put_line('   END IF;');
    dbms_output.put_line('END;');
    dbms_output.put_line('/');
 
     
  END;
 
  PROCEDURE script_merge_statement
           (target_table IN VARCHAR2,
            target_user  IN VARCHAR2 DEFAULT NULL
           )
  IS
    --4000 is maximum length for concatenated string
    column_list             VARCHAR2(4000);
    import_list             VARCHAR2(4000);
    target_list             VARCHAR2(4000);
    update_list             VARCHAR2(4000);
    on_and_exist_check_list VARCHAR2(4000);
    merge_where_list        VARCHAR2(4000);
   
    merge_where_list_c SYS_REFCURSOR; --get_merge_where_list
   
    managed_user VARCHAR2(30);
  BEGIN
    ----------------------------------------------------------------------------
    -- Variables
    managed_user := manage_user(target_user);
 
    WITH pk_info AS (
    SELECT constraint_name,
           owner,
           acc.table_name,
           column_name
      FROM all_cons_columns acc
        INNER JOIN all_constraints ac USING (constraint_name,owner)
     WHERE ac.constraint_type = 'P'
    ), last_col AS (
    SELECT owner,
           table_name,
           MAX(column_id) max_column_id
      FROM all_tab_columns
      GROUP BY owner,
           table_name
    )
    SELECT LISTAGG(LOWER(column_name), ', ')        column_list,
           LISTAGG('imp.' || LOWER(column_name), ', ')  import_list,
           LISTAGG('tgt.' || LOWER(column_name), ', ')  target_list,
           LISTAGG(CASE
                       WHEN constraint_name IS NULL
                         THEN 'tgt.' || LOWER(column_name) || ' = imp.' || LOWER(column_name)
                       ELSE NULL
                     END, ', ')                            update_list,
           LISTAGG(CASE
                       WHEN constraint_name IS NULL
                         THEN NULL
                       ELSE 'tgt.' || LOWER(column_name) || ' = imp.' || LOWER(column_name)
                     END, ' AND ') WITHIN GROUP (ORDER BY column_id) on_and_exist_check_list
      INTO column_list,
           import_list,
           target_list,
           update_list,
           on_and_exist_check_list
      FROM all_tab_columns
        INNER JOIN last_col USING(owner, table_name)
         LEFT JOIN pk_info USING(owner, table_name, column_name)
     WHERE UPPER(table_name) = UPPER(script_merge_statement.target_table)
       AND UPPER(owner) = UPPER(script_merge_statement.managed_user)
       AND UPPER(column_name) NOT LIKE UPPER('tracking_data_%') -- This is used where there is a column starting 'tracking_data_' which is used to track created and updated dates
     ORDER BY column_id
    ;
   
    -- CURSOR for MERGE WHERE
    merge_where_list_c := dm_code_creation.get_merge_where_list(UPPER(script_merge_statement.target_table),UPPER(script_merge_statement.managed_user));
   
    ----------------------------------------------------------------------------
    -- Output
   
    dbms_output.put_line('--------------------------------------------------------------------------------');
    dbms_output.put_line('-- MERGE -- ' || LOWER(script_merge_statement.managed_user) || '.' || LOWER(script_merge_statement.target_table));
    dbms_output.put_line('--------------------------------------------------------------------------------');
   
    ----------------------------------------------------------------------------
    dbms_output.put_line(' MERGE');
    dbms_output.put_line('  INTO ' || LOWER(script_merge_statement.managed_user) || '.' || LOWER(script_merge_statement.target_table) || ' tgt');
    dbms_output.put_line(' USING ' || '<source table>' || ' imp');
    dbms_output.put_line('    ON(' || on_and_exist_check_list || ')');
    dbms_output.put_line('  WHEN MATCHED THEN UPDATE');
    dbms_output.put_line('   SET ' || update_list);
   
    FETCH merge_where_list_c INTO merge_where_list;
    dbms_output.put_line(' WHERE ' || merge_where_list);
    LOOP
      FETCH merge_where_list_c INTO merge_where_list;
      EXIT WHEN merge_where_list_c%NOTFOUND;
 
      dbms_output.put_line('    OR ' || merge_where_list);
    END LOOP;
 
    dbms_output.put_line('  WHEN NOT MATCHED THEN');
    dbms_output.put_line('INSERT(' || target_list || ')');
    dbms_output.put_line('VALUES(' || import_list || ')');
    dbms_output.put_line(';');
  END;
 
  PROCEDURE script_insert_statement
           (target_table IN VARCHAR2,
            target_user  IN VARCHAR2 DEFAULT NULL
           )
  IS
    column_list  VARCHAR2(4000);
    pk_list      VARCHAR2(4000);
    managed_user VARCHAR2(30);
  BEGIN
    ----------------------------------------------------------------------------
    -- Variables
    managed_user := manage_user(target_user);
 
    --Column list
    SELECT LISTAGG(LOWER(column_name), ', ')
      INTO column_list
      FROM all_tab_columns
     WHERE UPPER(table_name) = UPPER(script_insert_statement.target_table)
       AND UPPER(owner) = UPPER(script_insert_statement.managed_user)
       AND UPPER(column_name) NOT LIKE UPPER('tracking_data_%') -- This is used where there is a column starting 'tracking_data_' which is used to track created and updated dates
     ORDER BY column_id
    ;
   
    --PK list, for WHERE NOT EXISTS
    SELECT LISTAGG(CASE
                       WHEN constraint_name IS NULL
                         THEN NULL
                       ELSE 'tgt.' || LOWER(column_name) || ' = imp.' || LOWER(column_name)
                     END, ' AND ') WITHIN GROUP (ORDER BY column_id) pk_list
      INTO pk_list
      FROM all_tab_columns
        INNER JOIN all_cons_columns acc USING (table_name,owner,column_name)
        INNER JOIN all_constraints ac   USING (table_name,owner,constraint_name)
     WHERE ac.constraint_type = 'P'
       AND UPPER(table_name) = UPPER(script_insert_statement.target_table)
       AND UPPER(owner)      = UPPER(script_insert_statement.managed_user)
       AND UPPER(column_name) NOT LIKE UPPER('tracking_data_%') -- This is used where there is a column starting 'tracking_data_' which is used to track created and updated dates
     ORDER BY column_id
    ;

    ----------------------------------------------------------------------------
    -- Output
   
    dbms_output.put_line('--------------------------------------------------------------------------------');
    dbms_output.put_line('-- INSERT -- ' || LOWER(script_insert_statement.managed_user) || '.' || LOWER(script_insert_statement.target_table));
    dbms_output.put_line('--------------------------------------------------------------------------------');
   
    ----------------------------------------------------------------------------
    dbms_output.put_line('INSERT');
    dbms_output.put_line('  INTO ' || LOWER(script_insert_statement.managed_user) || '.' || LOWER(script_insert_statement.target_table));
    ----------------------------------------------------------------------------
    --Create insert list
    dbms_output.put_line('      (' || column_list || ')');
    ----------------------------------------------------------------------------
    --Create select list
    dbms_output.put_line('SELECT ' || column_list);
    dbms_output.put_line('  FROM ' || '<source table> imp');
    ----------------------------------------------------------------------------
    --Create where not exists list
    dbms_output.put_line(' WHERE NOT EXISTS (SELECT * FROM '
                         || LOWER(script_insert_statement.managed_user) || '.' || LOWER(script_insert_statement.target_table)
                         || ' tgt'
                         || ' WHERE '
                         || pk_list
                         || ')');
   
    dbms_output.put_line(';');
  END;
 
END;
/