/*Checking data types in detailed*/

DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql +
    CASE WHEN @sql = N'' THEN N'' ELSE N'
UNION ALL
' END +
    N'SELECT ' +
    QUOTENAME(TABLE_NAME, '''') + N' AS table_name, ' +
    QUOTENAME(COLUMN_NAME, '''') + N' AS column_name, ' +
    N'COUNT(*) AS total_rows, ' +
    N'COUNT(' + QUOTENAME(COLUMN_NAME) + N') AS non_null_rows, ' +
    N'MAX(LEN(' + QUOTENAME(COLUMN_NAME) + N')) AS max_length, ' +
    N'MAX(DATALENGTH(' + QUOTENAME(COLUMN_NAME) + N')) AS max_bytes ' +
    N'FROM staging.' + QUOTENAME(TABLE_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'staging'
  AND DATA_TYPE IN ('varchar', 'nvarchar', 'char', 'nchar')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

SET @sql = N'SELECT * FROM (' + @sql + N') AS stats
ORDER BY table_name, column_name;';

EXEC sp_executesql @sql;

/* ==============================================================================
   CHECKING POSSIBLITIES FOR PK 
   ============================================================================== */

/*Checking duplicates on olist_geolocation*/
SELECT geolocation_zip_code_prefix, COUNT(DISTINCT geolocation_zip_code_prefix) AS duplicate_count
FROM staging.olist_geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT geolocation_zip_code_prefix) > 1;

/*Checking NULL in geolocation_zip_code_prefix*/
SELECT geolocation_zip_code_prefix
FROM staging.olist_geolocation
WHERE geolocation_zip_code_prefix IS NULL;

/*Checking (order_id, product_id) as PK in order_items*/
SELECT order_id, product_id, COUNT(*) AS duplicate_count
FROM staging.olist_order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

/*Checking (order_id, order_item_id) as PK in order_items*/
SELECT order_id, order_item_id, COUNT(*) AS duplicate_count
FROM staging.olist_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

/*Checking NULL in (order_id, item_id)*/
SELECT order_id, order_item_id
FROM staging.olist_order_items
WHERE order_id IS NULL OR order_item_id IS NULL;

/*Checking (order_id, payment_sequential) as PK in order_payments*/
SELECT order_id, payment_sequential, COUNT(*) AS duplicate_count
FROM staging.olist_order_payments
GROUP BY order_id,payment_sequential
HAVING COUNT(*) > 1;

/*Checking NULL in (order_id, payment_sequential)*/
SELECT order_id, payment_sequential
FROM staging.olist_order_payments
WHERE order_id IS NULL OR payment_sequential IS NULL;

/*Checking (review_id, order_id) as PK in order_reviews*/
SELECT review_id, order_id, COUNT(*) AS duplicate_count
FROM staging.olist_order_reviews
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;

/*Checking null in (review_id, order_id)*/
SELECT review_id, order_id
FROM staging.olist_order_reviews
WHERE review_id IS NULL OR order_id IS NULL;

/*Checking order_id as  PK in olist_orders*/
SELECT order_id, COUNT(*) AS duplicate_count
FROM staging.olist_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

/*Checking NULL in order_id*/
SELECT order_id
FROM staging.olist_orders
WHERE order_id IS NULL;

/*Checking product_id as  PK in olist_products*/
SELECT product_id, COUNT(*) AS duplicate_count
FROM staging.olist_products
GROUP BY product_id
HAVING COUNT(*) > 1;

/*Checking NULL in product_id*/
SELECT product_id
FROM staging.olist_order_items
WHERE product_id IS NULL;

/*Checking seller_id as PK in olist_sellers*/
SELECT seller_id, COUNT(*) AS duplicate_count
FROM staging.olist_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

/*Checking NULL in seller_id*/
SELECT seller_id
FROM staging.olist_sellers
WHERE seller_id IS NULL;

/*Checking product_category_name as PK in product_category_name_translation*/
SELECT product_category_name, COUNT(*) AS duplicate_count
FROM staging.product_category_name_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;

/*Checking NULL in product_category_name*/
SELECT product_category_name
FROM staging.product_category_name_translation
WHERE product_category_name IS NULL;

/* ==============================================================================
   CHECKING POSSIBLITIES FOR FK 
   ============================================================================== */
-- 1. customers -> geolocation
SELECT
    CAST('customers.customer_zip_code_prefix -> geolocation.geolocation_zip_code_prefix'
         AS VARCHAR(150)) AS relationship,
    CAST(LTRIM(RTRIM(c.customer_zip_code_prefix)) AS VARCHAR(100))
         AS orphan_value,
    COUNT_BIG(*) AS child_rows
FROM staging.olist_customers AS c
WHERE NULLIF(LTRIM(RTRIM(c.customer_zip_code_prefix)), '') IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.olist_geolocation AS g
      WHERE LTRIM(RTRIM(g.geolocation_zip_code_prefix))
          = LTRIM(RTRIM(c.customer_zip_code_prefix))
  )
GROUP BY LTRIM(RTRIM(c.customer_zip_code_prefix))

UNION ALL

-- 2. order_items -> orders
SELECT
    CAST('order_items.order_id -> orders.order_id' AS VARCHAR(150)),
    CAST(LTRIM(RTRIM(oi.order_id)) AS VARCHAR(100)),
    COUNT_BIG(*)
FROM staging.olist_order_items AS oi
WHERE NULLIF(LTRIM(RTRIM(oi.order_id)), '') IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.olist_orders AS o
      WHERE LTRIM(RTRIM(o.order_id)) = LTRIM(RTRIM(oi.order_id))
  )
GROUP BY LTRIM(RTRIM(oi.order_id))

UNION ALL

-- 3. order_items -> products
SELECT
    CAST('order_items.product_id -> products.product_id' AS VARCHAR(150)),
    CAST(LTRIM(RTRIM(oi.product_id)) AS VARCHAR(100)),
    COUNT_BIG(*)
FROM staging.olist_order_items AS oi
WHERE NULLIF(LTRIM(RTRIM(oi.product_id)), '') IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.olist_products AS p
      WHERE LTRIM(RTRIM(p.product_id)) = LTRIM(RTRIM(oi.product_id))
  )
GROUP BY LTRIM(RTRIM(oi.product_id))

UNION ALL

-- 4. order_items -> sellers
SELECT
    CAST('order_items.seller_id -> sellers.seller_id' AS VARCHAR(150)),
    CAST(LTRIM(RTRIM(oi.seller_id)) AS VARCHAR(100)),
    COUNT_BIG(*)
FROM staging.olist_order_items AS oi
WHERE NULLIF(LTRIM(RTRIM(oi.seller_id)), '') IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.olist_sellers AS s
      WHERE LTRIM(RTRIM(s.seller_id)) = LTRIM(RTRIM(oi.seller_id))
  )
GROUP BY LTRIM(RTRIM(oi.seller_id))

UNION ALL

-- 5. order_payments -> orders
SELECT
    CAST('order_payments.order_id -> orders.order_id' AS VARCHAR(150)),
    CAST(LTRIM(RTRIM(op.order_id)) AS VARCHAR(100)),
    COUNT_BIG(*)
FROM staging.olist_order_payments AS op
WHERE NULLIF(LTRIM(RTRIM(op.order_id)), '') IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.olist_orders AS o
      WHERE LTRIM(RTRIM(o.order_id)) = LTRIM(RTRIM(op.order_id))
  )
GROUP BY LTRIM(RTRIM(op.order_id))

UNION ALL

-- 6. order_reviews -> orders
SELECT
    CAST('order_reviews.order_id -> orders.order_id' AS VARCHAR(150)),
    CAST(LTRIM(RTRIM(r.order_id)) AS VARCHAR(100)),
    COUNT_BIG(*)
FROM staging.olist_order_reviews AS r
WHERE NULLIF(LTRIM(RTRIM(r.order_id)), '') IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.olist_orders AS o
      WHERE LTRIM(RTRIM(o.order_id)) = LTRIM(RTRIM(r.order_id))
  )
GROUP BY LTRIM(RTRIM(r.order_id))

UNION ALL

-- 7. orders -> customers
SELECT
    CAST('orders.customer_id -> customers.customer_id' AS VARCHAR(150)),
    CAST(LTRIM(RTRIM(o.customer_id)) AS VARCHAR(100)),
    COUNT_BIG(*)
FROM staging.olist_orders AS o
WHERE NULLIF(LTRIM(RTRIM(o.customer_id)), '') IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.olist_customers AS c
      WHERE LTRIM(RTRIM(c.customer_id)) = LTRIM(RTRIM(o.customer_id))
  )
GROUP BY LTRIM(RTRIM(o.customer_id))

UNION ALL

-- 8. products -> product_category
SELECT
    CAST('products.product_category_name -> product_category.product_category_name'
         AS VARCHAR(150)),
    CAST(LTRIM(RTRIM(p.product_category_name)) AS VARCHAR(100)),
    COUNT_BIG(*)
FROM staging.olist_products AS p
WHERE NULLIF(LTRIM(RTRIM(p.product_category_name)), '') IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.product_category AS pc
      WHERE LTRIM(RTRIM(pc.product_category_name))
          = LTRIM(RTRIM(p.product_category_name))
  )
GROUP BY LTRIM(RTRIM(p.product_category_name))

UNION ALL

-- 9. sellers -> geolocation
SELECT
    CAST('sellers.seller_zip_code_prefix -> geolocation.geolocation_zip_code_prefix'
         AS VARCHAR(150)),
    CAST(LTRIM(RTRIM(s.seller_zip_code_prefix)) AS VARCHAR(100)),
    COUNT_BIG(*)
FROM staging.olist_sellers AS s
WHERE NULLIF(LTRIM(RTRIM(s.seller_zip_code_prefix)), '') IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.olist_geolocation AS g
      WHERE LTRIM(RTRIM(g.geolocation_zip_code_prefix))
          = LTRIM(RTRIM(s.seller_zip_code_prefix))
  )
GROUP BY LTRIM(RTRIM(s.seller_zip_code_prefix))

ORDER BY relationship, orphan_value;

/*Checking FK for product_category_name_translation*/
SELECT *
FROM staging.olist_products
WHERE product_category_name IN (
    'pc_gamer',
    'portateis_cozinha_e_preparadores_de_alimentos'
);

SELECT *
FROM staging.product_category_name_translation
WHERE product_category_name IN (
    'pc_gamer',
    'portateis_cozinha_e_preparadores_de_alimentos'
);

/*Adding english meaning for these 2 categories in cleaned tables*/
-- CHECK: Customer ZIP prefix don't exist in geolocation

SELECT
    c.customer_zip_code_prefix,
    COUNT(*) AS total_rows
FROM staging.olist_customers AS c
WHERE NULLIF(LTRIM(RTRIM(c.customer_zip_code_prefix)), '') IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.olist_geolocation AS g
      WHERE LTRIM(RTRIM(g.geolocation_zip_code_prefix))
          = LTRIM(RTRIM(c.customer_zip_code_prefix))
  )
GROUP BY c.customer_zip_code_prefix
ORDER BY c.customer_zip_code_prefix;

-- CHECK: Seller ZIP prefix don't exist geolocation

SELECT
    s.seller_zip_code_prefix,
    COUNT(*) AS total_rows
FROM staging.olist_sellers AS s
WHERE NULLIF(LTRIM(RTRIM(s.seller_zip_code_prefix)), '') IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM staging.olist_geolocation AS g
      WHERE LTRIM(RTRIM(g.geolocation_zip_code_prefix))
          = LTRIM(RTRIM(s.seller_zip_code_prefix))
  )
GROUP BY s.seller_zip_code_prefix
ORDER BY s.seller_zip_code_prefix;


