/* =========================================================
   OLIST E-COMMERCE
   Schema: cleaning
   Purpose: Create cleaned tables, PKs and FKs
   Database: e_commerce
   ========================================================= */

-- 1. Create schema
IF SCHEMA_ID('cleaning') IS NULL
    EXEC('CREATE SCHEMA cleaning');
GO


/* =========================================================
   2. CREATE TABLES
   ========================================================= */

-- 2.1 Geolocation
CREATE TABLE cleaning.olist_geolocation (
    geolocation_zip_code_prefix VARCHAR(5) NOT NULL,
    geolocation_lat             DECIMAL(20,18) NOT NULL,
    geolocation_lng             DECIMAL(20,18) NOT NULL,
    geolocation_city            VARCHAR(38) NOT NULL,
    geolocation_state           VARCHAR(2) NOT NULL,

    CONSTRAINT PK_cleaning_olist_geolocation
        PRIMARY KEY (geolocation_zip_code_prefix)
);
GO


-- 2.2 Customers
CREATE TABLE cleaning.olist_customers (
    customer_id              VARCHAR(32) NOT NULL,
    customer_unique_id       VARCHAR(32) NOT NULL,
    customer_zip_code_prefix VARCHAR(5) NOT NULL,
    customer_city            VARCHAR(32) NOT NULL,
    customer_state           VARCHAR(2) NOT NULL,

    CONSTRAINT PK_cleaning_olist_customers
        PRIMARY KEY (customer_id)
);
GO


-- 2.3 Sellers
CREATE TABLE cleaning.olist_sellers (
    seller_id              VARCHAR(32) NOT NULL,
    seller_zip_code_prefix VARCHAR(5) NOT NULL,
    seller_city            VARCHAR(40) NOT NULL,
    seller_state           VARCHAR(2) NOT NULL,

    CONSTRAINT PK_cleaning_olist_sellers
        PRIMARY KEY (seller_id)
);
GO


-- 2.4 Product category translation
CREATE TABLE cleaning.product_category_name_translation (
    product_category_name         VARCHAR(46) NOT NULL,
    product_category_name_english VARCHAR(39) NOT NULL,

    CONSTRAINT PK_cleaning_product_category_translation
        PRIMARY KEY (product_category_name)
);
GO


-- 2.5 Products
CREATE TABLE cleaning.olist_products (
    product_id                 VARCHAR(32) NOT NULL,
    product_category_name      VARCHAR(46) NULL,
    product_name_lenght        INT NULL,
    product_description_lenght INT NULL,
    product_photos_qty         INT NULL,
    product_weight_g           INT NULL,
    product_length_cm          INT NULL,
    product_height_cm          INT NULL,
    product_width_cm           INT NULL,

    CONSTRAINT PK_cleaning_olist_products
        PRIMARY KEY (product_id)
);
GO


-- 2.6 Orders
CREATE TABLE cleaning.olist_orders (
    order_id                       VARCHAR(32) NOT NULL,
    customer_id                    VARCHAR(32) NOT NULL,
    order_status                   VARCHAR(11) NOT NULL,
    order_purchase_timestamp       DATETIME2(0) NOT NULL,
    order_approved_at              DATETIME2(0) NULL,
    order_delivered_carrier_date   DATETIME2(0) NULL,
    order_delivered_customer_date  DATETIME2(0) NULL,
    order_estimated_delivery_date  DATETIME2(0) NOT NULL,

    CONSTRAINT PK_cleaning_olist_orders
        PRIMARY KEY (order_id)
);
GO


-- 2.7 Order items
CREATE TABLE cleaning.olist_order_items (
    order_id           VARCHAR(32) NOT NULL,
    order_item_id      INT NOT NULL,
    product_id         VARCHAR(32) NOT NULL,
    seller_id          VARCHAR(32) NOT NULL,
    shipping_limit_date DATETIME2(0) NOT NULL,
    price              DECIMAL(10,2) NOT NULL,
    freight_value      DECIMAL(10,2) NOT NULL,

    CONSTRAINT PK_cleaning_olist_order_items
        PRIMARY KEY (order_id, order_item_id)
);
GO


-- 2.8 Order payments
CREATE TABLE cleaning.olist_order_payments (
    order_id            VARCHAR(32) NOT NULL,
    payment_sequential  INT NOT NULL,
    payment_type        VARCHAR(11) NOT NULL,
    payment_installments INT NOT NULL,
    payment_value       DECIMAL(7,2) NOT NULL,

    CONSTRAINT PK_cleaning_olist_order_payments
        PRIMARY KEY (order_id, payment_sequential)
);
GO


-- 2.9 Order reviews
CREATE TABLE cleaning.olist_order_reviews (
    review_id              VARCHAR(32) NOT NULL,
    order_id               VARCHAR(32) NOT NULL,
    review_score           INT NOT NULL,
    review_comment_title   VARCHAR(26) NULL,
    review_comment_message VARCHAR(208) NULL,
    review_creation_date   DATETIME2(0) NOT NULL,
    review_answer_timestamp DATETIME2(0) NOT NULL,

    CONSTRAINT PK_cleaning_olist_order_reviews
        PRIMARY KEY (review_id, order_id)
);
GO


/* =========================================================
   3. ADD FOREIGN KEYS
   Run this section after loading data and checking orphans.
   ========================================================= */

-- Customers -> Geolocation
ALTER TABLE cleaning.olist_customers
ADD CONSTRAINT FK_cleaning_customers_geolocation
    FOREIGN KEY (customer_zip_code_prefix)
    REFERENCES cleaning.olist_geolocation
        (geolocation_zip_code_prefix);
GO


-- Orders -> Customers
ALTER TABLE cleaning.olist_orders
ADD CONSTRAINT FK_cleaning_orders_customers
    FOREIGN KEY (customer_id)
    REFERENCES cleaning.olist_customers (customer_id);
GO


-- Order items -> Orders
ALTER TABLE cleaning.olist_order_items
ADD CONSTRAINT FK_cleaning_order_items_orders
    FOREIGN KEY (order_id)
    REFERENCES cleaning.olist_orders (order_id);
GO


-- Order items -> Products
ALTER TABLE cleaning.olist_order_items
ADD CONSTRAINT FK_cleaning_order_items_products
    FOREIGN KEY (product_id)
    REFERENCES cleaning.olist_products (product_id);
GO


-- Order items -> Sellers
ALTER TABLE cleaning.olist_order_items
ADD CONSTRAINT FK_cleaning_order_items_sellers
    FOREIGN KEY (seller_id)
    REFERENCES cleaning.olist_sellers (seller_id);
GO


-- Payments -> Orders
ALTER TABLE cleaning.olist_order_payments
ADD CONSTRAINT FK_cleaning_order_payments_orders
    FOREIGN KEY (order_id)
    REFERENCES cleaning.olist_orders (order_id);
GO


-- Reviews -> Orders
ALTER TABLE cleaning.olist_order_reviews
ADD CONSTRAINT FK_cleaning_order_reviews_orders
    FOREIGN KEY (order_id)
    REFERENCES cleaning.olist_orders (order_id);
GO


-- Products -> Product category translation
ALTER TABLE cleaning.olist_products
ADD CONSTRAINT FK_cleaning_products_category
    FOREIGN KEY (product_category_name)
    REFERENCES cleaning.product_category_name_translation
        (product_category_name);
GO


-- Sellers -> Geolocation
ALTER TABLE cleaning.olist_sellers
ADD CONSTRAINT FK_cleaning_sellers_geolocation
    FOREIGN KEY (seller_zip_code_prefix)
    REFERENCES cleaning.olist_geolocation
        (geolocation_zip_code_prefix);
GO