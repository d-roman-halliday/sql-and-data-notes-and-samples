-------------------------------------------------------------------------------
-- Create a database, with a user with full access to that database
-------------------------------------------------------------------------------
SHOW DATABASES;

-- Create the database
CREATE DATABASE IF NOT EXISTS xml_loader_example;

-- Create the user (if it doesn't already exist)
CREATE USER IF NOT EXISTS 'xml_loader_example_user'@'%' IDENTIFIED BY 'some_strong_password'; -- Replace with a real password!

-- Grant all privileges on the database to the user
GRANT ALL PRIVILEGES ON xml_loader_example.* TO 'xml_loader_example_user'@'%';

-- Flush privileges to ensure the changes take effect
FLUSH PRIVILEGES;

-------------------------------------------------------------------------------
-- More Examples
-------------------------------------------------------------------------------
CREATE USER 'davidrh'@'localhost' IDENTIFIED BY 'password';
ALTER USER 'davidrh'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
CREATE DATABASE david;
GRANT ALL PRIVILEGES ON david.* TO 'davidrh'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
