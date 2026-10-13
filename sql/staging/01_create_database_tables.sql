/* =========================================================
   OLIST E-COMMERCE
   Schema: staging
   Purpose: Create database and raw staging tables
   Database: e_commerce
   ========================================================= */

-- 1. Create database
CREATE DATABASE e_commerce;
GO

USE e_commerce;
GO

-- 2. Create schema
CREATE SCHEMA staging;
GO


/* =========================================================
   3. CREATE TABLES
   ========================================================= */

-- 3.1 Customers
CREATE TABLE staging.olist_customers (
    customer_id              VARCHAR(50),
    customer_unique_id       VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city            VARCHAR(100),
    customer_state           VARCHAR(10)
);
GO


-- 3.2 Sellers
CREATE TABLE staging.olist_sellers (
    seller_id              VARCHAR(50),
    seller_zip_code_prefix VARCHAR(10),
    seller_city            VARCHAR(100),
    seller_state           VARCHAR(10)
);
GO


-- 3.3 Geolocation
CREATE TABLE staging.olist_geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat             VARCHAR(50),
    geolocation_lng             VARCHAR(50),
    geolocation_city            VARCHAR(100),
    geolocation_state           VARCHAR(10)
);
GO


-- 3.4 Product category
CREATE TABLE staging.product_category (
    product_category_name         VARCHAR(100),
    product_category_name_english VARCHAR(100)
);
GO


-- 3.5 Products
CREATE TABLE staging.olist_products (
    product_id                 VARCHAR(50),
    product_category_name      VARCHAR(100),
    product_name_lenght        VARCHAR(20),
    product_description_lenght VARCHAR(20),
    product_photos_qty         VARCHAR(20),
    product_weight_g           VARCHAR(20),
    product_length_cm          VARCHAR(20),
    product_height_cm          VARCHAR(20),
    product_width_cm           VARCHAR(20)
);
GO


-- 3.6 Orders
CREATE TABLE staging.olist_orders (
    order_id                       VARCHAR(50),
    customer_id                    VARCHAR(50),
    order_status                   VARCHAR(50),
    order_purchase_timestamp       VARCHAR(50),
    order_approved_at              VARCHAR(50),
    order_delivered_carrier_date   VARCHAR(50),
    order_delivered_customer_date  VARCHAR(50),
    order_estimated_delivery_date  VARCHAR(50)
);
GO


-- 3.7 Order items
CREATE TABLE staging.olist_order_items (
    order_id            VARCHAR(50),
    order_item_id       VARCHAR(20),
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date VARCHAR(50),
    price               VARCHAR(20),
    freight_value       VARCHAR(20)
);
GO


-- 3.8 Order payments
CREATE TABLE staging.olist_order_payments (
    order_id             VARCHAR(50),
    payment_sequential   VARCHAR(20),
    payment_type         VARCHAR(50),
    payment_installments VARCHAR(20),
    payment_value        VARCHAR(20)
);
GO


-- 3.9 Order reviews
CREATE TABLE staging.olist_order_reviews (
    review_id               VARCHAR(50),
    order_id                VARCHAR(50),
    review_score            VARCHAR(20),
    review_comment_title    VARCHAR(500),
    review_comment_message  VARCHAR(MAX),
    review_creation_date    VARCHAR(50),
    review_answer_timestamp VARCHAR(50)
);
GO


-- 3.10 Product category name translation
CREATE TABLE staging.product_category_name_translation (
    product_category_name         VARCHAR(100),
    product_category_name_english VARCHAR(100)
);
GO
```