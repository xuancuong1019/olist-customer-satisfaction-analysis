-- Row Count Verification
SELECT 'olist_customers' AS t, COUNT(*) AS cnt FROM staging.olist_customers
UNION ALL SELECT 'olist_sellers', COUNT(*) FROM staging.olist_sellers
UNION ALL SELECT 'olist_geolocation', COUNT(*) FROM staging.olist_geolocation
UNION ALL SELECT 'product_category', COUNT(*) FROM staging.product_category
UNION ALL SELECT 'olist_products', COUNT(*) FROM staging.olist_products
UNION ALL SELECT 'olist_orders', COUNT(*) FROM staging.olist_orders
UNION ALL SELECT 'olist_order_items', COUNT(*) FROM staging.olist_order_items
UNION ALL SELECT 'olist_order_payments', COUNT(*) FROM staging.olist_order_payments
UNION ALL SELECT 'olist_order_reviews', COUNT(*) FROM staging.olist_order_reviews;


-- Schema & Structure Check
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    ORDINAL_POSITION AS column_order,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH AS max_length_chars,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    DATETIME_PRECISION,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'staging'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- Uniqueness Check
SELECT review_id, COUNT(*) cnt FROM staging.olist_order_reviews GROUP BY review_id HAVING COUNT(*) > 1;

SELECT review_id, order_id, COUNT(*) as so_lan_lap
FROM staging.olist_order_reviews
GROUP BY review_id,  order_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*) cnt FROM staging.olist_orders GROUP BY order_id HAVING COUNT(*) > 1;
SELECT customer_id, COUNT(*) cnt FROM staging.olist_customers GROUP BY customer_id HAVING COUNT(*) > 1;
SELECT seller_id, COUNT(*) cnt FROM staging.olist_sellers GROUP BY seller_id HAVING COUNT(*) > 1;
SELECT product_id, COUNT(*) cnt FROM staging.olist_products GROUP BY product_id HAVING COUNT(*) > 1;



-- Missing Values Check
-- =========================================================
-- MISSING VALUES CHECK - Toàn bộ 9 bảng staging
-- Output: table_name | column_name | missing_count
-- =========================================================

-- 1. olist_customers
SELECT 'olist_customers' AS table_name, 'customer_id' AS column_name,
    SUM(CASE WHEN customer_id IS NULL OR customer_id = '' THEN 1 ELSE 0 END) AS missing_count
FROM staging.olist_customers
UNION ALL
SELECT 'olist_customers', 'customer_unique_id',
    SUM(CASE WHEN customer_unique_id IS NULL OR customer_unique_id = '' THEN 1 ELSE 0 END)
FROM staging.olist_customers
UNION ALL
SELECT 'olist_customers', 'customer_zip_code_prefix',
    SUM(CASE WHEN customer_zip_code_prefix IS NULL OR customer_zip_code_prefix = '' THEN 1 ELSE 0 END)
FROM staging.olist_customers
UNION ALL
SELECT 'olist_customers', 'customer_city',
    SUM(CASE WHEN customer_city IS NULL OR customer_city = '' THEN 1 ELSE 0 END)
FROM staging.olist_customers
UNION ALL
SELECT 'olist_customers', 'customer_state',
    SUM(CASE WHEN customer_state IS NULL OR customer_state = '' THEN 1 ELSE 0 END)
FROM staging.olist_customers

UNION ALL

-- 2. olist_sellers
SELECT 'olist_sellers', 'seller_id',
    SUM(CASE WHEN seller_id IS NULL OR seller_id = '' THEN 1 ELSE 0 END)
FROM staging.olist_sellers
UNION ALL
SELECT 'olist_sellers', 'seller_zip_code_prefix',
    SUM(CASE WHEN seller_zip_code_prefix IS NULL OR seller_zip_code_prefix = '' THEN 1 ELSE 0 END)
FROM staging.olist_sellers
UNION ALL
SELECT 'olist_sellers', 'seller_city',
    SUM(CASE WHEN seller_city IS NULL OR seller_city = '' THEN 1 ELSE 0 END)
FROM staging.olist_sellers
UNION ALL
SELECT 'olist_sellers', 'seller_state',
    SUM(CASE WHEN seller_state IS NULL OR seller_state = '' THEN 1 ELSE 0 END)
FROM staging.olist_sellers

UNION ALL

-- 3. olist_order_reviews
SELECT 'olist_order_reviews', 'review_id',
    SUM(CASE WHEN review_id IS NULL OR review_id = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_reviews
UNION ALL
SELECT 'olist_order_reviews', 'order_id',
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_reviews
UNION ALL
SELECT 'olist_order_reviews', 'review_score',
    SUM(CASE WHEN review_score IS NULL OR review_score = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_reviews
UNION ALL
SELECT 'olist_order_reviews', 'review_comment_title',
    SUM(CASE WHEN review_comment_title IS NULL OR review_comment_title = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_reviews
UNION ALL
SELECT 'olist_order_reviews', 'review_comment_message',
    SUM(CASE WHEN review_comment_message IS NULL OR review_comment_message = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_reviews
UNION ALL
SELECT 'olist_order_reviews', 'review_creation_date',
    SUM(CASE WHEN review_creation_date IS NULL OR review_creation_date = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_reviews
UNION ALL
SELECT 'olist_order_reviews', 'review_answer_timestamp',
    SUM(CASE WHEN review_answer_timestamp IS NULL OR review_answer_timestamp = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_reviews

UNION ALL

-- 4. olist_order_payments
SELECT 'olist_order_payments', 'order_id',
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_payments
UNION ALL
SELECT 'olist_order_payments', 'payment_sequential',
    SUM(CASE WHEN payment_sequential IS NULL OR payment_sequential = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_payments
UNION ALL
SELECT 'olist_order_payments', 'payment_type',
    SUM(CASE WHEN payment_type IS NULL OR payment_type = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_payments
UNION ALL
SELECT 'olist_order_payments', 'payment_installments',
    SUM(CASE WHEN payment_installments IS NULL OR payment_installments = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_payments
UNION ALL
SELECT 'olist_order_payments', 'payment_value',
    SUM(CASE WHEN payment_value IS NULL OR payment_value = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_payments

UNION ALL

-- 5. olist_orders
SELECT 'olist_orders', 'order_id',
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END)
FROM staging.olist_orders
UNION ALL
SELECT 'olist_orders', 'customer_id',
    SUM(CASE WHEN customer_id IS NULL OR customer_id = '' THEN 1 ELSE 0 END)
FROM staging.olist_orders
UNION ALL
SELECT 'olist_orders', 'order_status',
    SUM(CASE WHEN order_status IS NULL OR order_status = '' THEN 1 ELSE 0 END)
FROM staging.olist_orders
UNION ALL
SELECT 'olist_orders', 'order_purchase_timestamp',
    SUM(CASE WHEN order_purchase_timestamp IS NULL OR order_purchase_timestamp = '' THEN 1 ELSE 0 END)
FROM staging.olist_orders
UNION ALL
SELECT 'olist_orders', 'order_approved_at',
    SUM(CASE WHEN order_approved_at IS NULL OR order_approved_at = '' THEN 1 ELSE 0 END)
FROM staging.olist_orders
UNION ALL
SELECT 'olist_orders', 'order_delivered_carrier_date',
    SUM(CASE WHEN order_delivered_carrier_date IS NULL OR order_delivered_carrier_date = '' THEN 1 ELSE 0 END)
FROM staging.olist_orders
UNION ALL
SELECT 'olist_orders', 'order_delivered_customer_date',
    SUM(CASE WHEN order_delivered_customer_date IS NULL OR order_delivered_customer_date = '' THEN 1 ELSE 0 END)
FROM staging.olist_orders
UNION ALL
SELECT 'olist_orders', 'order_estimated_delivery_date',
    SUM(CASE WHEN order_estimated_delivery_date IS NULL OR order_estimated_delivery_date = '' THEN 1 ELSE 0 END)
FROM staging.olist_orders

UNION ALL

-- 6. olist_order_items
SELECT 'olist_order_items', 'order_id',
    SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_items
UNION ALL
SELECT 'olist_order_items', 'order_item_id',
    SUM(CASE WHEN order_item_id IS NULL OR order_item_id = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_items
UNION ALL
SELECT 'olist_order_items', 'product_id',
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_items
UNION ALL
SELECT 'olist_order_items', 'seller_id',
    SUM(CASE WHEN seller_id IS NULL OR seller_id = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_items
UNION ALL
SELECT 'olist_order_items', 'shipping_limit_date',
    SUM(CASE WHEN shipping_limit_date IS NULL OR shipping_limit_date = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_items
UNION ALL
SELECT 'olist_order_items', 'price',
    SUM(CASE WHEN price IS NULL OR price = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_items
UNION ALL
SELECT 'olist_order_items', 'freight_value',
    SUM(CASE WHEN freight_value IS NULL OR freight_value = '' THEN 1 ELSE 0 END)
FROM staging.olist_order_items

UNION ALL

-- 7. olist_products
SELECT 'olist_products', 'product_id',
    SUM(CASE WHEN product_id IS NULL OR product_id = '' THEN 1 ELSE 0 END)
FROM staging.olist_products
UNION ALL
SELECT 'olist_products', 'product_category_name',
    SUM(CASE WHEN product_category_name IS NULL OR product_category_name = '' THEN 1 ELSE 0 END)
FROM staging.olist_products
UNION ALL
SELECT 'olist_products', 'product_name_lenght',
    SUM(CASE WHEN product_name_lenght IS NULL OR product_name_lenght = '' THEN 1 ELSE 0 END)
FROM staging.olist_products
UNION ALL
SELECT 'olist_products', 'product_description_lenght',
    SUM(CASE WHEN product_description_lenght IS NULL OR product_description_lenght = '' THEN 1 ELSE 0 END)
FROM staging.olist_products
UNION ALL
SELECT 'olist_products', 'product_photos_qty',
    SUM(CASE WHEN product_photos_qty IS NULL OR product_photos_qty = '' THEN 1 ELSE 0 END)
FROM staging.olist_products
UNION ALL
SELECT 'olist_products', 'product_weight_g',
    SUM(CASE WHEN product_weight_g IS NULL OR product_weight_g = '' THEN 1 ELSE 0 END)
FROM staging.olist_products
UNION ALL
SELECT 'olist_products', 'product_length_cm',
    SUM(CASE WHEN product_length_cm IS NULL OR product_length_cm = '' THEN 1 ELSE 0 END)
FROM staging.olist_products
UNION ALL
SELECT 'olist_products', 'product_height_cm',
    SUM(CASE WHEN product_height_cm IS NULL OR product_height_cm = '' THEN 1 ELSE 0 END)
FROM staging.olist_products
UNION ALL
SELECT 'olist_products', 'product_width_cm',
    SUM(CASE WHEN product_width_cm IS NULL OR product_width_cm = '' THEN 1 ELSE 0 END)
FROM staging.olist_products

UNION ALL

-- 8. product_category
SELECT 'product_category', 'product_category_name',
    SUM(CASE WHEN product_category_name IS NULL OR product_category_name = '' THEN 1 ELSE 0 END)
FROM staging.product_category
UNION ALL
SELECT 'product_category', 'product_category_name_english',
    SUM(CASE WHEN product_category_name_english IS NULL OR product_category_name_english = '' THEN 1 ELSE 0 END)
FROM staging.product_category

UNION ALL

-- 9. olist_geolocation
SELECT 'olist_geolocation', 'geolocation_zip_code_prefix',
    SUM(CASE WHEN geolocation_zip_code_prefix IS NULL OR geolocation_zip_code_prefix = '' THEN 1 ELSE 0 END)
FROM staging.olist_geolocation
UNION ALL
SELECT 'olist_geolocation', 'geolocation_lat',
    SUM(CASE WHEN geolocation_lat IS NULL OR geolocation_lat = '' THEN 1 ELSE 0 END)
FROM staging.olist_geolocation
UNION ALL
SELECT 'olist_geolocation', 'geolocation_lng',
    SUM(CASE WHEN geolocation_lng IS NULL OR geolocation_lng = '' THEN 1 ELSE 0 END)
FROM staging.olist_geolocation
UNION ALL
SELECT 'olist_geolocation', 'geolocation_city',
    SUM(CASE WHEN geolocation_city IS NULL OR geolocation_city = '' THEN 1 ELSE 0 END)
FROM staging.olist_geolocation
UNION ALL
SELECT 'olist_geolocation', 'geolocation_state',
    SUM(CASE WHEN geolocation_state IS NULL OR geolocation_state = '' THEN 1 ELSE 0 END)
FROM staging.olist_geolocation

ORDER BY table_name, column_name;


-- Referential Integrity Check
SELECT COUNT(*) AS orphan_orders_customer FROM staging.olist_orders o
LEFT JOIN staging.olist_customers c ON o.customer_id = c.customer_id WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS orphan_items_order FROM staging.olist_order_items oi
LEFT JOIN staging.olist_orders o ON oi.order_id = o.order_id WHERE o.order_id IS NULL;

SELECT COUNT(*) AS orphan_items_product FROM staging.olist_order_items oi
LEFT JOIN staging.olist_products p ON oi.product_id = p.product_id WHERE p.product_id IS NULL;

SELECT COUNT(*) AS orphan_items_seller FROM staging.olist_order_items oi
LEFT JOIN staging.olist_sellers s ON oi.seller_id = s.seller_id WHERE s.seller_id IS NULL;

SELECT COUNT(*) AS orphan_payments FROM staging.olist_order_payments p
LEFT JOIN staging.olist_orders o ON p.order_id = o.order_id WHERE o.order_id IS NULL;

SELECT COUNT(*) AS orphan_reviews FROM staging.olist_order_reviews r
LEFT JOIN staging.olist_orders o ON r.order_id = o.order_id WHERE o.order_id IS NULL;

SELECT COUNT(*) AS orphan_products_category FROM staging.olist_products p
LEFT JOIN staging.product_category c ON p.product_category_name = c.product_category_name
WHERE p.product_category_name IS NOT NULL AND c.product_category_name IS NULL;

-- Data covert checking
SELECT order_id, order_purchase_timestamp FROM staging.olist_orders
WHERE TRY_CAST(order_purchase_timestamp AS DATETIME2) IS NULL AND order_purchase_timestamp NOT IN ('', NULL);

SELECT order_id, price, freight_value FROM staging.olist_order_items
WHERE TRY_CAST(price AS DECIMAL(10,2)) IS NULL OR TRY_CAST(freight_value AS DECIMAL(10,2)) IS NULL;

SELECT order_id, order_purchase_timestamp, order_delivered_customer_date
FROM staging.olist_orders
WHERE TRY_CAST(order_delivered_customer_date AS DATETIME2) < TRY_CAST(order_purchase_timestamp AS DATETIME2);


-- Domain / Value Range Check
SELECT order_status, COUNT(*) cnt FROM staging.olist_orders GROUP BY order_status ORDER BY cnt DESC;
SELECT payment_type, COUNT(*) cnt FROM staging.olist_order_payments GROUP BY payment_type ORDER BY cnt DESC;
SELECT review_score, COUNT(*) cnt FROM staging.olist_order_reviews GROUP BY review_score ORDER BY review_score;

SELECT COUNT(*) AS negative_price FROM staging.olist_order_items WHERE TRY_CAST(price AS DECIMAL(10,2)) < 0;
SELECT COUNT(*) AS negative_freight FROM staging.olist_order_items WHERE TRY_CAST(freight_value AS DECIMAL(10,2)) < 0;

SELECT COUNT(DISTINCT customer_id) AS total_customer_id, COUNT(DISTINCT customer_unique_id) AS total_unique_customer
FROM staging.olist_customers;

/* Sau khi khảo sát, số lượng giá trị độc nhất của cột customer_id và customer_unique_id là khác nhau (99441 > 96096). Trong khi 
bảng olist_customers không ghi nhận bất kì giá trị khuyết nào (99441 dòng). Nghi vấn: customer_unique_id xác định một khách hàng 
thật sự, còn customer_id là mã khách hàng được tạo khi một người đặt đơn hàng bất kì. Đề xuất phương án giải quyết là dùng tập hợp 
customer_id và customer_unique_id để xác định một khách hàng khi mua một đơn hàng duy nhất. */

SELECT customer_id, customer_unique_id, COUNT(*) AS so_lan_lap
FROM staging.olist_customers
GROUP BY customer_id, customer_unique_id
HAVING COUNT(*) > 1;

SELECT DISTINCT p.product_category_name
FROM staging.olist_products p
LEFT JOIN staging.product_category c ON p.product_category_name = c.product_category_name
WHERE p.product_category_name IS NOT NULL AND c.product_category_name IS NULL;

