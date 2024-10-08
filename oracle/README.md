# Oracle

## Code Creation

This is a package of stored procedures for generating code.

### Working example

Crete tables as in `simple_shop_model.sql`
Create stored package

```
SET SERVEROUTPUT ON;
CALL dm_code_creation.script_add_dates('people');
CALL dm_code_creation.script_merge_statement('people');
CALL dm_code_creation.script_insert_statement('people');
```

Produces:

```
--------------------------------------------------------------------------------
-- Add Date Tracking -- david.people
--------------------------------------------------------------------------------
-- Add Columns
ALTER TABLE david.people
ADD(tracking_data_date_created DATE DEFAULT SYSDATE NOT NULL,
    tracking_data_date_updated DATE DEFAULT SYSDATE NOT NULL
)
;
--INDEX THEM
CREATE
 INDEX people_dc
    ON people
      (tracking_data_date_created)
       NOLOGGING
;
CREATE
 INDEX people_du
    ON people
      (tracking_data_date_updated)
       NOLOGGING
;

--Create trigger
CREATE TRIGGER people_bu
BEFORE UPDATE
   ON people
   FOR EACH ROW
BEGIN
   IF((:NEW.PERSON_ID IS NULL AND :OLD.PERSON_ID IS NOT NULL) OR (:NEW.PERSON_ID IS NOT NULL AND :OLD.PERSON_ID IS NULL) OR (:NEW.PERSON_ID<>:OLD.PERSON_ID))
      OR((:NEW.FIRST_NAME IS NULL AND :OLD.FIRST_NAME IS NOT NULL) OR (:NEW.FIRST_NAME IS NOT NULL AND :OLD.FIRST_NAME IS NULL) OR (:NEW.FIRST_NAME<>:OLD.FIRST_NAME))
      OR((:NEW.LAST_NAME IS NULL AND :OLD.LAST_NAME IS NOT NULL) OR (:NEW.LAST_NAME IS NOT NULL AND :OLD.LAST_NAME IS NULL) OR (:NEW.LAST_NAME<>:OLD.LAST_NAME))
      OR((:NEW.EMAIL IS NULL AND :OLD.EMAIL IS NOT NULL) OR (:NEW.EMAIL IS NOT NULL AND :OLD.EMAIL IS NULL) OR (:NEW.EMAIL<>:OLD.EMAIL))
      OR((:NEW.PHONE_NUMBER IS NULL AND :OLD.PHONE_NUMBER IS NOT NULL) OR (:NEW.PHONE_NUMBER IS NOT NULL AND :OLD.PHONE_NUMBER IS NULL) OR (:NEW.PHONE_NUMBER<>:OLD.PHONE_NUMBER))
   THEN
      :new.tracking_data_date_updated := SYSDATE;
   END IF;
END;
/


--------------------------------------------------------------------------------
-- MERGE -- david.people
--------------------------------------------------------------------------------
 MERGE
  INTO david.people tgt
 USING <source table> imp
    ON(tgt.person_id = imp.person_id)
  WHEN MATCHED THEN UPDATE
   SET tgt.first_name = imp.first_name, tgt.email = imp.email, tgt.last_name = imp.last_name, tgt.phone_number = imp.phone_number
 WHERE DECODE(tgt.first_name,imp.first_name,1,0) = 0 OR DECODE(tgt.last_name,imp.last_name,1,0) = 0 OR DECODE(tgt.email,imp.email,1,0) = 0 OR DECODE(tgt.phone_number,imp.phone_number,1,0) = 0
  WHEN NOT MATCHED THEN
INSERT(tgt.person_id, tgt.email, tgt.last_name, tgt.phone_number, tgt.first_name)
VALUES(imp.person_id, imp.email, imp.last_name, imp.phone_number, imp.first_name)
;


--------------------------------------------------------------------------------
-- INSERT -- david.people
--------------------------------------------------------------------------------
INSERT
  INTO david.people
      (person_id, first_name, last_name, email, phone_number)
SELECT person_id, first_name, last_name, email, phone_number
  FROM <source table> imp
 WHERE NOT EXISTS (SELECT * FROM david.people tgt WHERE tgt.person_id = imp.person_id)
;


```