/*
When creating a new table to store more data/more detail it's important to
make sure it's compatible with the old table (and anything which inserted
data into it)/pulled data from it.
*/

----------------------------------------------------------------------------
-- Method 1 (good for a more complete proc)
----------------------------------------------------------------------------
BEGIN;
	DECLARE @ErrorMessage VARCHAR(MAX);

	DECLARE @objName_NEW_Table VARCHAR(MAX) = '[schema].[table_1]';
	DECLARE @objName_OLD_Table VARCHAR(MAX) = '[schema].[table_2]';

	DECLARE @objId_NEW_Table BIGINT = OBJECT_ID(@objName_NEW_Table, N'U');
	DECLARE @objId_OLD_Table BIGINT = OBJECT_ID(@objName_OLD_Table, N'U');

    IF @objId_NEW_Table IS NULL
    BEGIN;
        SET @ErrorMessage = N'Table not found - New : ' + @objName_NEW_Table;
        THROW 51000, @ErrorMessage, 1;
    END;

    IF @objId_OLD_Table IS NULL
    BEGIN;
        SET @ErrorMessage = N'Table not found - Old : ' + @objName_OLD_Table;
        THROW 51000, @ErrorMessage, 1;
    END;


    WITH new_table AS (
    SELECT c.[name],
           c.[system_type_id],
           c.[max_length],
           c.[precision],
           c.[scale]
      FROM [sys].[all_columns] c
        INNER JOIN [sys].[all_objects] o ON o.[object_id] = c.[object_id]
     WHERE o.[object_id] = @objId_NEW_Table
    ), old_table AS (
    SELECT c.[name],
           c.[system_type_id],
           c.[max_length],
           c.[precision],
           c.[scale]
      FROM [sys].[all_columns] c
        INNER JOIN [sys].[all_objects] o ON o.[object_id] = c.[object_id]
     WHERE o.[object_id] = @objId_OLD_Table
    )
    SELECT COALESCE(new.[name],old.[name])                                         AS [name],
           CASE WHEN new.[name] IS NULL                          THEN 0 ELSE 1 END AS [exists_in_NEW],
           CASE WHEN old.[name] IS NULL                          THEN 0 ELSE 1 END AS [exists_in_OLD],
           CASE WHEN new.[system_type_id] = old.[system_type_id] THEN 1 ELSE 0 END AS [matches_system_type_id], -- The OLD table can have less detailed data, but not more!
           CASE WHEN new.[max_length]    <= old.[max_length]     THEN 1 ELSE 0 END AS [matches_max_length],     -- The OLD table can have less detailed data, but not more!
           CASE WHEN new.[precision]     <= old.[precision]      THEN 1 ELSE 0 END AS [matches_precision],      -- The OLD table can have less detailed data, but not more!
           CASE WHEN new.[scale]         <= old.[scale]          THEN 1 ELSE 0 END AS [matches_scale],          -- The OLD table can have less detailed data, but not more!
           nt.[name]                                                               AS [type_name_NEW],
           ot.[name]                                                               AS [type_name_OLD],
           new.[max_length]                                                        AS [max_length_NEW],
           old.[max_length]                                                        AS [max_length_OLD],
           new.[precision]                                                         AS [precision_NEW],
           old.[precision]                                                         AS [precision_OLD]
      FROM old_table old
        FULL JOIN new_table new ON new.[name] = old.[name]
        LEFT JOIN sys.types  nt ON nt.[system_type_id] = new.[system_type_id]
        LEFT JOIN sys.types  ot ON ot.[system_type_id] = old.[system_type_id]
	 ORDER BY COALESCE(new.[name],old.[name])
    ;
END;

GO
----------------------------------------------------------------------------
-- Method 2 (compact)
----------------------------------------------------------------------------
DECLARE @objName_NEW_Table VARCHAR(MAX) = '[schema].[table_1]';
DECLARE @objName_OLD_Table VARCHAR(MAX) = '[schema].[table_2]';

WITH new_table AS (
SELECT c.[name],
       c.[system_type_id],
       c.[max_length],
       c.[precision],
       c.[scale]
    FROM [sys].[all_columns] c
    INNER JOIN [sys].[all_objects] o ON o.[object_id] = c.[object_id]
    WHERE o.[object_id] = OBJECT_ID(@objName_NEW_Table, N'U')
), old_table AS (
SELECT c.[name],
        c.[system_type_id],
        c.[max_length],
        c.[precision],
        c.[scale]
    FROM [sys].[all_columns] c
    INNER JOIN [sys].[all_objects] o ON o.[object_id] = c.[object_id]
    WHERE o.[object_id] = OBJECT_ID(@objName_OLD_Table, N'U')
)
SELECT COALESCE(new.[name],old.[name])                                         AS [name],
       CASE WHEN new.[name] IS NULL                          THEN 0 ELSE 1 END AS [exists_in_NEW],
       CASE WHEN old.[name] IS NULL                          THEN 0 ELSE 1 END AS [exists_in_OLD],
       CASE WHEN new.[system_type_id] = old.[system_type_id] THEN 1 ELSE 0 END AS [matches_system_type_id], -- The OLD table can have less detailed data, but not more!
       CASE WHEN new.[max_length]    <= old.[max_length]     THEN 1 ELSE 0 END AS [matches_max_length],     -- The OLD table can have less detailed data, but not more!
       CASE WHEN new.[precision]     <= old.[precision]      THEN 1 ELSE 0 END AS [matches_precision],      -- The OLD table can have less detailed data, but not more!
       CASE WHEN new.[scale]         <= old.[scale]          THEN 1 ELSE 0 END AS [matches_scale],          -- The OLD table can have less detailed data, but not more!
       nt.[name]        AS [type_name_NEW],
       ot.[name]        AS [type_name_OLD],
       new.[max_length] AS [max_length_NEW],
       old.[max_length] AS [max_length_OLD],
       new.[precision]  AS [precision_NEW],
       old.[precision]  AS [precision_OLD]
  FROM old_table old
     FULL JOIN new_table new ON new.[name] = old.[name]
     LEFT JOIN sys.types  nt ON nt.[system_type_id] = new.[system_type_id]
     LEFT JOIN sys.types  ot ON ot.[system_type_id] = old.[system_type_id]
	ORDER BY COALESCE(new.[name],old.[name])
;
