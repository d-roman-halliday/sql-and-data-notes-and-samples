--------------------------------------------------------------------------------
-- Some basic user admin
--
-- Older documentation: https://blogs.oracle.com/sql/post/how-to-create-users-grant-them-privileges-and-remove-them-in-oracle-database
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Create a user & give permissions for general development
-- Valid for Oracle 23ai (using new role DB_DEVELOPER_ROLE): https://docs.oracle.com/en/database/oracle/oracle-database/23/dbseg/managing-security-for-application-developers.html
--------------------------------------------------------------------------------

-- Create
CREATE USER <username> IDENTIFIED BY "<password>";

-- Change/reset password
ALTER USER <username> IDENTIFIED BY "<password>";

-- Grant DB_DEVELOPER_ROLEL: The DB_DEVELOPER_ROLE role provides most of the system privileges, object privileges, predefined roles, PL/SQL package privileges, and tracing privileges that an application developer needs.
GRANT DB_DEVELOPER_ROLE TO <username>;

-- Grant tablespace (otherwise user can't insert rows to tables they create)
GRANT UNLIMITED TABLESPACE TO <username>;
