
/* =========================================================
   OLIST E-COMMERCE
   Script: 03_transform_and_load.sql
   Purpose:
       1. Check invalid numeric and datetime values
       2. Normalize blank strings to NULL where appropriate
       3. Convert staging columns to cleaning data types
       4. Load data into cleaning tables

   Important:
       - Do not add foreign keys before loading.
       - This script expects empty cleaning tables.
       - Missing values are not imputed.
   ========================================================= */

USE e_commerce;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;


/* =========================================================
   1. PRE-CHECK: DESTINATION TABLES MUST BE EMPTY
   ========================================================= */

IF EXISTS (SELECT 1 FROM cleaning.olist_geolocation)
OR EXISTS (SELECT 1 FROM cleaning.olist_customers)
OR EXISTS (SELECT 1 FROM cleaning.olist_sellers)
OR EXISTS (SELECT 1 FROM cleaning.product_category_name_translation)
OR EXISTS (SELECT 1 FROM cleaning.olist_products)
OR EXISTS (SELECT 1 FROM cleaning.olist_orders)
OR EXISTS (SELECT 1 FROM cleaning.olist_order_items)
OR EXISTS (SELECT 1 FROM cleaning.olist_order_payments)
OR EXISTS (SELECT 1 FROM cleaning.olist_order_reviews)
BEGIN
    THROW 51000,
        'Cleaning tables are not empty. Check existing data before loading.',
        1;
END;
GO


/* =========================================================
   2. CHECK INVALID NUMERIC AND DATETIME CONVERSIONS

   Blank strings are treated as missing, not as conversion errors.
   Nonblank values that cannot be converted are reported.
   ========================================================= */

CREATE TABLE #ConversionErrors (
    source_table  VARCHAR(100),
    column_name   VARCHAR(100),
    invalid_value NVARCHAR(4000)
);

INSERT INTO #ConversionErrors
    (source_table, column_name, invalid_value)

-- 2.1 Geolocation
SELECT 'staging.olist_geolocation', 'geolocation_lat',
       CONVERT(NVARCHAR(4000), geolocation_lat)
FROM staging.olist_geolocation
WHERE NULLIF(LTRIM(RTRIM(geolocation_lat)), '') IS NOT NULL
  AND TRY_CONVERT(
        DECIMAL(22,18),
        NULLIF(LTRIM(RTRIM(geolocation_lat)), '')
      ) IS NULL

UNION ALL

SELECT 'staging.olist_geolocation', 'geolocation_lng',
       CONVERT(NVARCHAR(4000), geolocation_lng)
FROM staging.olist_geolocation
WHERE NULLIF(LTRIM(RTRIM(geolocation_lng)), '') IS NOT NULL
  AND TRY_CONVERT(
        DECIMAL(22,18),
        NULLIF(LTRIM(RTRIM(geolocation_lng)), '')
      ) IS NULL

-- 2.2 Products
UNION ALL

SELECT 'staging.olist_products', 'product_name_lenght',
       CONVERT(NVARCHAR(4000), product_name_lenght)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_name_lenght)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_name_lenght)), '')) IS NULL

UNION ALL

SELECT 'staging.olist_products', 'product_description_lenght',
       CONVERT(NVARCHAR(4000), product_description_lenght)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_description_lenght)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_description_lenght)), '')) IS NULL

UNION ALL

SELECT 'staging.olist_products', 'product_photos_qty',
       CONVERT(NVARCHAR(4000), product_photos_qty)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_photos_qty)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_photos_qty)), '')) IS NULL

UNION ALL

SELECT 'staging.olist_products', 'product_weight_g',
       CONVERT(NVARCHAR(4000), product_weight_g)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_weight_g)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_weight_g)), '')) IS NULL

UNION ALL

SELECT 'staging.olist_products', 'product_length_cm',
       CONVERT(NVARCHAR(4000), product_length_cm)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_length_cm)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_length_cm)), '')) IS NULL

UNION ALL

SELECT 'staging.olist_products', 'product_height_cm',
       CONVERT(NVARCHAR(4000), product_height_cm)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_height_cm)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_height_cm)), '')) IS NULL

UNION ALL

SELECT 'staging.olist_products', 'product_width_cm',
       CONVERT(NVARCHAR(4000), product_width_cm)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_width_cm)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_width_cm)), '')) IS NULL

-- 2.3 Orders: timestamps
UNION ALL

SELECT 'staging.olist_orders', 'order_purchase_timestamp',
       CONVERT(NVARCHAR(4000), order_purchase_timestamp)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_purchase_timestamp)), '') IS NOT NULL
  AND TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_purchase_timestamp)), ''),
        120
      ) IS NULL

UNION ALL

SELECT 'staging.olist_orders', 'order_approved_at',
       CONVERT(NVARCHAR(4000), order_approved_at)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_approved_at)), '') IS NOT NULL
  AND TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_approved_at)), ''),
        120
      ) IS NULL

UNION ALL

SELECT 'staging.olist_orders', 'order_delivered_carrier_date',
       CONVERT(NVARCHAR(4000), order_delivered_carrier_date)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)), '') IS NOT NULL
  AND TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)), ''),
        120
      ) IS NULL

UNION ALL

SELECT 'staging.olist_orders', 'order_delivered_customer_date',
       CONVERT(NVARCHAR(4000), order_delivered_customer_date)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), '') IS NOT NULL
  AND TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), ''),
        120
      ) IS NULL

UNION ALL

SELECT 'staging.olist_orders', 'order_estimated_delivery_date',
       CONVERT(NVARCHAR(4000), order_estimated_delivery_date)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), '') IS NOT NULL
  AND TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), ''),
        120
      ) IS NULL

-- 2.4 Order items
UNION ALL

SELECT 'staging.olist_order_items', 'order_item_id',
       CONVERT(NVARCHAR(4000), order_item_id)
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(order_item_id)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(order_item_id)), '')) IS NULL

UNION ALL

SELECT 'staging.olist_order_items', 'shipping_limit_date',
       CONVERT(NVARCHAR(4000), shipping_limit_date)
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(shipping_limit_date)), '') IS NOT NULL
  AND TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(shipping_limit_date)), ''),
        120
      ) IS NULL

UNION ALL

SELECT 'staging.olist_order_items', 'price',
       CONVERT(NVARCHAR(4000), price)
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(price)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM(price)), '')) IS NULL

UNION ALL

SELECT 'staging.olist_order_items', 'freight_value',
       CONVERT(NVARCHAR(4000), freight_value)
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(freight_value)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM(freight_value)), '')) IS NULL

-- 2.5 Payments
UNION ALL

SELECT 'staging.olist_order_payments', 'payment_sequential',
       CONVERT(NVARCHAR(4000), payment_sequential)
FROM staging.olist_order_payments
WHERE NULLIF(LTRIM(RTRIM(payment_sequential)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(payment_sequential)), '')) IS NULL

UNION ALL

SELECT 'staging.olist_order_payments', 'payment_installments',
       CONVERT(NVARCHAR(4000), payment_installments)
FROM staging.olist_order_payments
WHERE NULLIF(LTRIM(RTRIM(payment_installments)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(payment_installments)), '')) IS NULL

UNION ALL

SELECT 'staging.olist_order_payments', 'payment_value',
       CONVERT(NVARCHAR(4000), payment_value)
FROM staging.olist_order_payments
WHERE NULLIF(LTRIM(RTRIM(payment_value)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(7,2), NULLIF(LTRIM(RTRIM(payment_value)), '')) IS NULL

-- 2.6 Reviews
UNION ALL

SELECT 'staging.olist_order_reviews', 'review_score',
       CONVERT(NVARCHAR(4000), review_score)
FROM staging.olist_order_reviews
WHERE NULLIF(LTRIM(RTRIM(review_score)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(review_score)), '')) IS NULL

UNION ALL

SELECT 'staging.olist_order_reviews', 'review_creation_date',
       CONVERT(NVARCHAR(4000), review_creation_date)
FROM staging.olist_order_reviews
WHERE NULLIF(LTRIM(RTRIM(review_creation_date)), '') IS NOT NULL
  AND TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(review_creation_date)), ''),
        120
      ) IS NULL

UNION ALL

SELECT 'staging.olist_order_reviews', 'review_answer_timestamp',
       CONVERT(NVARCHAR(4000), review_answer_timestamp)
FROM staging.olist_order_reviews
WHERE NULLIF(LTRIM(RTRIM(review_answer_timestamp)), '') IS NOT NULL
  AND TRY_CONVERT(
        DATETIME2(0),
        NULLIF(LTRIM(RTRIM(review_answer_timestamp)), ''),
        120
      ) IS NULL;


/* Stop before loading if invalid nonblank values were found. */

IF EXISTS (SELECT 1 FROM #ConversionErrors)
BEGIN
    SELECT
        source_table,
        column_name,
        invalid_value
    FROM #ConversionErrors
    ORDER BY source_table, column_name;

    THROW 51001,
        'Invalid numeric or datetime values found. Review the result set before loading.',
        1;
END;

/*CHECKING*/

SELECT
    source_table,
    column_name,
    invalid_value
FROM #ConversionErrors
ORDER BY source_table, column_name;

SELECT
    TRY_CONVERT(FLOAT, '-4.36738e-005') AS value_float,
    TRY_CONVERT(
        DECIMAL(22,18),
        TRY_CONVERT(FLOAT, '-4.36738e-005')
    ) AS value_decimal;

DROP TABLE #ConversionErrors;
GO




/* =========================================================
   3. TRANSFORM AND LOAD
   ========================================================= */

BEGIN TRY
    BEGIN TRANSACTION;

    /* 3.1 Geolocation
       Convert through FLOAT to support scientific notation,
       then convert to DECIMAL(22,18).
    */
    INSERT INTO cleaning.olist_geolocation (
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    )
    SELECT
        NULLIF(LTRIM(RTRIM(geolocation_zip_code_prefix)), ''),
        TRY_CONVERT(
            DECIMAL(22,18),
            TRY_CONVERT(
                FLOAT,
                NULLIF(LTRIM(RTRIM(geolocation_lat)), '')
            )
        ),
        TRY_CONVERT(
            DECIMAL(22,18),
            TRY_CONVERT(
                FLOAT,
                NULLIF(LTRIM(RTRIM(geolocation_lng)), '')
            )
        ),
        NULLIF(LTRIM(RTRIM(geolocation_city)), ''),
        NULLIF(LTRIM(RTRIM(geolocation_state)), '')
    FROM staging.olist_geolocation;


    /* 3.2 Customers */
    INSERT INTO cleaning.olist_customers (
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    )
    SELECT
        NULLIF(LTRIM(RTRIM(customer_id)), ''),
        NULLIF(LTRIM(RTRIM(customer_unique_id)), ''),
        NULLIF(LTRIM(RTRIM(customer_zip_code_prefix)), ''),
        NULLIF(LTRIM(RTRIM(customer_city)), ''),
        NULLIF(LTRIM(RTRIM(customer_state)), '')
    FROM staging.olist_customers;


    /* 3.3 Sellers */
    INSERT INTO cleaning.olist_sellers (
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    )
    SELECT
        NULLIF(LTRIM(RTRIM(seller_id)), ''),
        NULLIF(LTRIM(RTRIM(seller_zip_code_prefix)), ''),
        NULLIF(LTRIM(RTRIM(seller_city)), ''),
        NULLIF(LTRIM(RTRIM(seller_state)), '')
    FROM staging.olist_sellers;


    /* 3.4 Product category translation
       Load source translations first.
    */
    INSERT INTO cleaning.product_category_name_translation (
        product_category_name,
        product_category_name_english
    )
    SELECT
        NULLIF(LTRIM(RTRIM(product_category_name)), ''),
        NULLIF(LTRIM(RTRIM(product_category_name_english)), '')
    FROM staging.product_category_name_translation;


    /* Add documented manual translations for the two
       categories missing from the source translation table.
    */
    INSERT INTO cleaning.product_category_name_translation (
        product_category_name,
        product_category_name_english
    )
    SELECT
        v.product_category_name,
        v.product_category_name_english
    FROM (
        VALUES
            ('pc_gamer', 'gaming_pc'),
            (
                'portateis_cozinha_e_preparadores_de_alimentos',
                'kitchen_portables_and_food_preparers'
            )
    ) AS v(product_category_name, product_category_name_english)
    WHERE NOT EXISTS (
        SELECT 1
        FROM cleaning.product_category_name_translation AS t
        WHERE t.product_category_name = v.product_category_name
    );


    /* 3.5 Products */
    INSERT INTO cleaning.olist_products (
        product_id,
        product_category_name,
        product_name_lenght,
        product_description_lenght,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    )
    SELECT
        NULLIF(LTRIM(RTRIM(product_id)), ''),
        NULLIF(LTRIM(RTRIM(product_category_name)), ''),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_name_lenght)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_description_lenght)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_photos_qty)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_weight_g)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_length_cm)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_height_cm)), '')),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_width_cm)), ''))
    FROM staging.olist_products;


    /* 3.6 Orders */
    INSERT INTO cleaning.olist_orders (
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date
    )
    SELECT
        NULLIF(LTRIM(RTRIM(order_id)), ''),
        NULLIF(LTRIM(RTRIM(customer_id)), ''),
        NULLIF(LTRIM(RTRIM(order_status)), ''),
        TRY_CONVERT(DATETIME2(0),
            NULLIF(LTRIM(RTRIM(order_purchase_timestamp)), ''), 120),
        TRY_CONVERT(DATETIME2(0),
            NULLIF(LTRIM(RTRIM(order_approved_at)), ''), 120),
        TRY_CONVERT(DATETIME2(0),
            NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)), ''), 120),
        TRY_CONVERT(DATETIME2(0),
            NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), ''), 120),
        TRY_CONVERT(DATETIME2(0),
            NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), ''), 120)
    FROM staging.olist_orders;


    /* 3.7 Order items */
    INSERT INTO cleaning.olist_order_items (
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    )
    SELECT
        NULLIF(LTRIM(RTRIM(order_id)), ''),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(order_item_id)), '')),
        NULLIF(LTRIM(RTRIM(product_id)), ''),
        NULLIF(LTRIM(RTRIM(seller_id)), ''),
        TRY_CONVERT(DATETIME2(0),
            NULLIF(LTRIM(RTRIM(shipping_limit_date)), ''), 120),
        TRY_CONVERT(DECIMAL(10,2),
            NULLIF(LTRIM(RTRIM(price)), '')),
        TRY_CONVERT(DECIMAL(10,2),
            NULLIF(LTRIM(RTRIM(freight_value)), ''))
    FROM staging.olist_order_items;


    /* 3.8 Order payments */
    INSERT INTO cleaning.olist_order_payments (
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
    )
    SELECT
        NULLIF(LTRIM(RTRIM(order_id)), ''),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(payment_sequential)), '')),
        NULLIF(LTRIM(RTRIM(payment_type)), ''),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(payment_installments)), '')),
        TRY_CONVERT(DECIMAL(7,2),
            NULLIF(LTRIM(RTRIM(payment_value)), ''))
    FROM staging.olist_order_payments;


    /* 3.9 Order reviews */
    INSERT INTO cleaning.olist_order_reviews (
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
    )
    SELECT
        NULLIF(LTRIM(RTRIM(review_id)), ''),
        NULLIF(LTRIM(RTRIM(order_id)), ''),
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(review_score)), '')),
        NULLIF(LTRIM(RTRIM(review_comment_title)), ''),
        NULLIF(LTRIM(RTRIM(review_comment_message)), ''),
        TRY_CONVERT(DATETIME2(0),
            NULLIF(LTRIM(RTRIM(review_creation_date)), ''), 120),
        TRY_CONVERT(DATETIME2(0),
            NULLIF(LTRIM(RTRIM(review_answer_timestamp)), ''), 120)
    FROM staging.olist_order_reviews;


    COMMIT TRANSACTION;

    PRINT 'Data successfully loaded into cleaning tables.';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO


/* =========================================================
   4. ROW COUNT VALIDATION
   ========================================================= */

SELECT 'olist_geolocation' AS table_name,
       (SELECT COUNT_BIG(*) FROM staging.olist_geolocation) AS staging_rows,
       (SELECT COUNT_BIG(*) FROM cleaning.olist_geolocation) AS cleaning_rows

UNION ALL
SELECT 'olist_customers',
       (SELECT COUNT_BIG(*) FROM staging.olist_customers),
       (SELECT COUNT_BIG(*) FROM cleaning.olist_customers)

UNION ALL
SELECT 'olist_sellers',
       (SELECT COUNT_BIG(*) FROM staging.olist_sellers),
       (SELECT COUNT_BIG(*) FROM cleaning.olist_sellers)

UNION ALL
SELECT 'product_category_name_translation',
       (SELECT COUNT_BIG(*) FROM staging.product_category_name_translation),
       (SELECT COUNT_BIG(*) FROM cleaning.product_category_name_translation)

UNION ALL
SELECT 'olist_products',
       (SELECT COUNT_BIG(*) FROM staging.olist_products),
       (SELECT COUNT_BIG(*) FROM cleaning.olist_products)

UNION ALL
SELECT 'olist_orders',
       (SELECT COUNT_BIG(*) FROM staging.olist_orders),
       (SELECT COUNT_BIG(*) FROM cleaning.olist_orders)

UNION ALL
SELECT 'olist_order_items',
       (SELECT COUNT_BIG(*) FROM staging.olist_order_items),
       (SELECT COUNT_BIG(*) FROM cleaning.olist_order_items)

UNION ALL
SELECT 'olist_order_payments',
       (SELECT COUNT_BIG(*) FROM staging.olist_order_payments),
       (SELECT COUNT_BIG(*) FROM cleaning.olist_order_payments)

UNION ALL
SELECT 'olist_order_reviews',
       (SELECT COUNT_BIG(*) FROM staging.olist_order_reviews),
       (SELECT COUNT_BIG(*) FROM cleaning.olist_order_reviews);
GO
