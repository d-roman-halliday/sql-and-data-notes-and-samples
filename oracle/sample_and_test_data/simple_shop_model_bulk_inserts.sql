--------------------------------------------------------------------------------
-- A simple Shop Model
--
-- Tables:
--  - people
--  - products
--  - shopping_cart_items
--  - shopping_carts
--------------------------------------------------------------------------------
-- For dbfiddle.uk this required changes for bulk inserts
-- (so I didn't have too many blocks)
-- See working: https://dbfiddle.uk/TGgT2V5_
--------------------------------------------------------------------------------
-- people
--------------------------------------------------------------------------------
DROP TABLE IF EXISTS people;

CREATE TABLE people
(
    person_id       NUMBER(38)   NOT NULL PRIMARY KEY,
    first_name      VARCHAR2(26) NOT NULL,
    last_name       VARCHAR2(26),
    email           VARCHAR2(26),
    phone_number    VARCHAR2(26)
);

INSERT ALL 
    INTO people(person_id, first_name, last_name, email, phone_number) VALUES (1, 'John', 'Doe', 'johndoe@example.com', '555-123-4567')
    INTO people(person_id, first_name, last_name, email, phone_number) VALUES (2, 'Jane', 'Smith', 'janesmith@example.com', '555-987-6543')
    INTO people(person_id, first_name, last_name, email, phone_number) VALUES (3, 'Robert', 'Johnson', 'robertjohnson@example.com', '555-234-5678')
    INTO people(person_id, first_name, last_name, email, phone_number) VALUES (4, 'Emily', 'Wilson', 'emilywilson@example.com', '555-876-5432')
    INTO people(person_id, first_name, last_name, email, phone_number) VALUES (5, 'Michael', 'Brown', 'michaelbrown@example.com', '555-345-6789')
SELECT 1 FROM dual;

--------------------------------------------------------------------------------
-- products
--------------------------------------------------------------------------------
DROP TABLE IF EXISTS products;

CREATE TABLE products
(
    product_id      NUMBER(38)    NOT NULL PRIMARY KEY,
    product_name    VARCHAR2(50)  NOT NULL,
    price           NUMBER(38, 2) NOT NULL
);

INSERT ALL 
    INTO products (product_id, product_name, price) VALUES (101, 'Smartphone', 499.99)
	INTO products (product_id, product_name, price) VALUES (102, 'Laptop', 899.99)
	INTO products (product_id, product_name, price) VALUES (103, 'Headphones', 99.99)
	INTO products (product_id, product_name, price) VALUES (104, 'TV', 799.99)
	INTO products (product_id, product_name, price) VALUES (105, 'Tablet', 299.99)
SELECT 1 FROM dual;

--------------------------------------------------------------------------------
-- shopping_cart_items
--------------------------------------------------------------------------------
DROP TABLE IF EXISTS shopping_cart_items;

CREATE TABLE shopping_cart_items
(
    cart_item_id    NUMBER(38) NOT NULL PRIMARY KEY,
    cart_id         NUMBER(38) NOT NULL,
    product_id      NUMBER(38) NOT NULL,
    quantity        NUMBER(38) NOT NULL
);

INSERT ALL 
    INTO shopping_cart_items (cart_item_id, cart_id, product_id, quantity) VALUES (1, 1, 101, 2)
    INTO shopping_cart_items (cart_item_id, cart_id, product_id, quantity) VALUES (2, 1, 103, 1)
    INTO shopping_cart_items (cart_item_id, cart_id, product_id, quantity) VALUES (3, 2, 102, 1)
    INTO shopping_cart_items (cart_item_id, cart_id, product_id, quantity) VALUES (4, 2, 104, 1)
    INTO shopping_cart_items (cart_item_id, cart_id, product_id, quantity) VALUES (5, 2, 105, 1)
    INTO shopping_cart_items (cart_item_id, cart_id, product_id, quantity) VALUES (6, 3, 101, 1)
    INTO shopping_cart_items (cart_item_id, cart_id, product_id, quantity) VALUES (7, 3, 104, 1)
    INTO shopping_cart_items (cart_item_id, cart_id, product_id, quantity) VALUES (8, 4, 102, 1)
    INTO shopping_cart_items (cart_item_id, cart_id, product_id, quantity) VALUES (9, 5, 103, 2)
    INTO shopping_cart_items (cart_item_id, cart_id, product_id, quantity) VALUES (10, 5, 105, 1)
SELECT 1 FROM dual
;

--------------------------------------------------------------------------------
-- shopping_carts
--------------------------------------------------------------------------------
DROP TABLE IF EXISTS shopping_carts;

CREATE TABLE shopping_carts
(
    cart_id         NUMBER(38) NOT NULL,
    person_id       NUMBER(38) NOT NULL,
    sale_date       DATE
);

INSERT ALL 
    INTO shopping_carts (cart_id, person_id, sale_date) VALUES (1, 1, to_date('2023-10-18', 'YYYY-MM-DD'))   
    INTO shopping_carts (cart_id, person_id, sale_date) VALUES (2, 2, to_date('2023-10-18', 'YYYY-MM-DD'))   
    INTO shopping_carts (cart_id, person_id, sale_date) VALUES (3, 3, to_date('2023-10-17', 'YYYY-MM-DD'))   
    INTO shopping_carts (cart_id, person_id, sale_date) VALUES (4, 4, to_date('2023-10-17', 'YYYY-MM-DD'))   
    INTO shopping_carts (cart_id, person_id, sale_date) VALUES (5, 5, to_date('2023-10-16', 'YYYY-MM-DD'))   
SELECT 1 FROM dual
;

--------------------------------------------------------------------------------
-- Sample Select
--------------------------------------------------------------------------------
SELECT
    *
FROM
    SHOPPING_CARTS
    LEFT JOIN SHOPPING_CART_ITEMS USING ( CART_ID )
    LEFT JOIN PRODUCTS USING ( PRODUCT_ID )
    LEFT JOIN PEOPLE USING ( PERSON_ID )
;