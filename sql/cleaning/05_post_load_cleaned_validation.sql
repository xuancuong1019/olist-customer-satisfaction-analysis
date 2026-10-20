/* ==============================================================================
   PROJECT     : OLIST E-COMMERCE ANALYTICS
   SCRIPT NAME : 05_post_load_cleaned_validation.sql
   PURPOSE     : 
       1. Row Count Reconciliation: Đối chiếu tổng số dòng giữa [staging] và [cleaning].
       2. Silent Conversion Failure Check: Đảm bảo TRY_CONVERT không làm mất dữ liệu hợp lệ.
       3. Primary Key Readiness: Kiểm tra trùng lặp và NULL trên các cột dự kiến làm PK.
       4. Referential Integrity (FK Readiness): Đảm bảo 0% bản ghi mồ côi trước khi tạo FK.
   ============================================================================== */

USE e_commerce;
GO

SET NOCOUNT ON;


-- ==============================================================================
-- SECTION 1: ROW COUNT RECONCILIATION (Đối chiếu số lượng bản ghi)
-- ==============================================================================
/* Business Question: Toàn bộ dữ liệu từ [staging] đã được nạp đủ sang [cleaning] 
   chưa? (Lưu ý: Bảng translation ở cleaning sẽ nhiều hơn 2 dòng do ta chủ động inject). */

WITH StagingCounts AS (
    SELECT 'olist_geolocation'                   AS table_name, COUNT(*) AS staging_rows FROM staging.olist_geolocation UNION ALL
    SELECT 'olist_customers'                     AS table_name, COUNT(*) FROM staging.olist_customers UNION ALL
    SELECT 'olist_sellers'                       AS table_name, COUNT(*) FROM staging.olist_sellers UNION ALL
    SELECT 'product_category_name_translation'   AS table_name, COUNT(*) FROM staging.product_category_name_translation UNION ALL
    SELECT 'olist_products'                      AS table_name, COUNT(*) FROM staging.olist_products UNION ALL
    SELECT 'olist_orders'                        AS table_name, COUNT(*) FROM staging.olist_orders UNION ALL
    SELECT 'olist_order_items'                   AS table_name, COUNT(*) FROM staging.olist_order_items UNION ALL
    SELECT 'olist_order_payments'                AS table_name, COUNT(*) FROM staging.olist_order_payments UNION ALL
    SELECT 'olist_order_reviews'                 AS table_name, COUNT(*) FROM staging.olist_order_reviews
),
CleaningCounts AS (
    SELECT 'olist_geolocation'                   AS table_name, COUNT(*) AS cleaning_rows FROM cleaning.olist_geolocation UNION ALL
    SELECT 'olist_customers'                     AS table_name, COUNT(*) FROM cleaning.olist_customers UNION ALL
    SELECT 'olist_sellers'                       AS table_name, COUNT(*) FROM cleaning.olist_sellers UNION ALL
    SELECT 'product_category_name_translation'   AS table_name, COUNT(*) FROM cleaning.product_category_name_translation UNION ALL
    SELECT 'olist_products'                      AS table_name, COUNT(*) FROM cleaning.olist_products UNION ALL
    SELECT 'olist_orders'                        AS table_name, COUNT(*) FROM cleaning.olist_orders UNION ALL
    SELECT 'olist_order_items'                   AS table_name, COUNT(*) FROM cleaning.olist_order_items UNION ALL
    SELECT 'olist_order_payments'                AS table_name, COUNT(*) FROM cleaning.olist_order_payments UNION ALL
    SELECT 'olist_order_reviews'                 AS table_name, COUNT(*) FROM cleaning.olist_order_reviews
)
SELECT 
    s.table_name,
    s.staging_rows,
    c.cleaning_rows,
    (c.cleaning_rows - s.staging_rows) AS row_diff,
    CASE 
        WHEN s.table_name = 'product_category_name_translation' AND (c.cleaning_rows - s.staging_rows) = 2 THEN '✅ PASS (+2 Injected)'
        WHEN c.cleaning_rows = s.staging_rows THEN '✅ PASS'
        ELSE '❌ FAIL: Row mismatch'
    END AS validation_status
FROM StagingCounts s
INNER JOIN CleaningCounts c ON s.table_name = c.table_name
ORDER BY s.table_name;


-- ==============================================================================
-- SECTION 2: SILENT CONVERSION FAILURE CHECK (Kiểm tra rớt dữ liệu ngầm)
-- ==============================================================================
/* Business Question: Các hàm TRY_CONVERT (đặc biệt là tọa độ có chữ 'e' và các cột 
   ngày tháng/tiền tệ) có vô tình biến giá trị hợp lệ nào thành NULL hay không? 
   Kỳ vọng: non_null_diff = 0 ở tất cả các cột. */

SELECT 
    'olist_geolocation.geolocation_lat' AS target_column,
    (SELECT COUNT(*) FROM staging.olist_geolocation WHERE NULLIF(LTRIM(RTRIM(geolocation_lat)), '') IS NOT NULL) AS staging_valid_cnt,
    (SELECT COUNT(*) FROM cleaning.olist_geolocation WHERE geolocation_lat IS NOT NULL)                          AS cleaning_valid_cnt
UNION ALL
SELECT 
    'olist_geolocation.geolocation_lng',
    (SELECT COUNT(*) FROM staging.olist_geolocation WHERE NULLIF(LTRIM(RTRIM(geolocation_lng)), '') IS NOT NULL),
    (SELECT COUNT(*) FROM cleaning.olist_geolocation WHERE geolocation_lng IS NOT NULL)
UNION ALL
SELECT 
    'olist_orders.order_purchase_timestamp',
    (SELECT COUNT(*) FROM staging.olist_orders WHERE NULLIF(LTRIM(RTRIM(order_purchase_timestamp)), '') IS NOT NULL),
    (SELECT COUNT(*) FROM cleaning.olist_orders WHERE order_purchase_timestamp IS NOT NULL)
UNION ALL
SELECT 
    'olist_orders.order_approved_at',
    (SELECT COUNT(*) FROM staging.olist_orders WHERE NULLIF(LTRIM(RTRIM(order_approved_at)), '') IS NOT NULL),
    (SELECT COUNT(*) FROM cleaning.olist_orders WHERE order_approved_at IS NOT NULL)
UNION ALL
SELECT 
    'olist_order_items.price',
    (SELECT COUNT(*) FROM staging.olist_order_items WHERE NULLIF(LTRIM(RTRIM(price)), '') IS NOT NULL),
    (SELECT COUNT(*) FROM cleaning.olist_order_items WHERE price IS NOT NULL)
UNION ALL
SELECT 
    'olist_order_payments.payment_value',
    (SELECT COUNT(*) FROM staging.olist_order_payments WHERE NULLIF(LTRIM(RTRIM(payment_value)), '') IS NOT NULL),
    (SELECT COUNT(*) FROM cleaning.olist_order_payments WHERE payment_value IS NOT NULL);


-- ==============================================================================
-- SECTION 3: PRIMARY KEY READINESS (Kiểm tra điều kiện thiết lập Khóa chính)
-- ==============================================================================
/* Business Question: Các cột định danh (Single PK hoặc Composite PK) trong tầng 
   [cleaning] có bị trùng lặp hoặc chứa giá trị NULL hay không? 
   Kỳ vọng: duplicate_keys = 0 và null_keys = 0. */

-- Lưu ý nghiệp vụ: 
-- 1. olist_order_items dùng Composite PK: (order_id, order_item_id)
-- 2. olist_order_payments dùng Composite PK: (order_id, payment_sequential)
-- 3. olist_order_reviews dùng Composite PK: (review_id, order_id) do 1 review_id có thể gắn với nhiều order_id.

SELECT 
    'olist_customers (customer_id)' AS pk_candidate,
    (SELECT COUNT(*) - COUNT(DISTINCT customer_id) FROM cleaning.olist_customers) AS duplicate_keys,
    (SELECT COUNT(*) FROM cleaning.olist_customers WHERE customer_id IS NULL)     AS null_keys
UNION ALL
SELECT 
    'olist_sellers (seller_id)',
    (SELECT COUNT(*) - COUNT(DISTINCT seller_id) FROM cleaning.olist_sellers),
    (SELECT COUNT(*) FROM cleaning.olist_sellers WHERE seller_id IS NULL)
UNION ALL
SELECT 
    'product_category_name_translation (product_category_name)',
    (SELECT COUNT(*) - COUNT(DISTINCT product_category_name) FROM cleaning.product_category_name_translation),
    (SELECT COUNT(*) FROM cleaning.product_category_name_translation WHERE product_category_name IS NULL)
UNION ALL
SELECT 
    'olist_products (product_id)',
    (SELECT COUNT(*) - COUNT(DISTINCT product_id) FROM cleaning.olist_products),
    (SELECT COUNT(*) FROM cleaning.olist_products WHERE product_id IS NULL)
UNION ALL
SELECT 
    'olist_orders (order_id)',
    (SELECT COUNT(*) - COUNT(DISTINCT order_id) FROM cleaning.olist_orders),
    (SELECT COUNT(*) FROM cleaning.olist_orders WHERE order_id IS NULL)
UNION ALL
SELECT 
    'olist_order_items (order_id, order_item_id)',
    (SELECT COUNT(*) FROM (SELECT order_id, order_item_id FROM cleaning.olist_order_items GROUP BY order_id, order_item_id HAVING COUNT(*) > 1) t),
    (SELECT COUNT(*) FROM cleaning.olist_order_items WHERE order_id IS NULL OR order_item_id IS NULL)
UNION ALL
SELECT 
    'olist_order_payments (order_id, payment_sequential)',
    (SELECT COUNT(*) FROM (SELECT order_id, payment_sequential FROM cleaning.olist_order_payments GROUP BY order_id, payment_sequential HAVING COUNT(*) > 1) t),
    (SELECT COUNT(*) FROM cleaning.olist_order_payments WHERE order_id IS NULL OR payment_sequential IS NULL)
UNION ALL
SELECT 
    'olist_order_reviews (review_id, order_id)',
    (SELECT COUNT(*) FROM (SELECT review_id, order_id FROM cleaning.olist_order_reviews GROUP BY review_id, order_id HAVING COUNT(*) > 1) t),
    (SELECT COUNT(*) FROM cleaning.olist_order_reviews WHERE review_id IS NULL OR order_id IS NULL);


-- ==============================================================================
-- SECTION 4: FOREIGN KEY READINESS (Kiểm tra toàn vẹn tham chiếu trên bảng sạch)
-- ==============================================================================
/* Business Question: Sau khi đã inject 2 danh mục tiếng Bồ Đào Nha bị thiếu, 
   còn bất kỳ bản ghi mồ côi (Orphan Record) nào cản trở việc tạo Foreign Key không? 
   Kỳ vọng: orphan_count = 0 trên toàn bộ các mối quan hệ. */

SELECT 'orders -> customers' AS fk_relationship, COUNT(*) AS orphan_count
FROM cleaning.olist_orders o
LEFT JOIN cleaning.olist_customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT 'order_items -> orders', COUNT(*)
FROM cleaning.olist_order_items oi
LEFT JOIN cleaning.olist_orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'order_items -> products', COUNT(*)
FROM cleaning.olist_order_items oi
LEFT JOIN cleaning.olist_products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT 'order_items -> sellers', COUNT(*)
FROM cleaning.olist_order_items oi
LEFT JOIN cleaning.olist_sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL

UNION ALL

SELECT 'order_payments -> orders', COUNT(*)
FROM cleaning.olist_order_payments p
LEFT JOIN cleaning.olist_orders o ON p.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'order_reviews -> orders', COUNT(*)
FROM cleaning.olist_order_reviews r
LEFT JOIN cleaning.olist_orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'products -> category_translation', COUNT(*)
FROM cleaning.olist_products p
LEFT JOIN cleaning.product_category_name_translation c ON p.product_category_name = c.product_category_name
WHERE p.product_category_name IS NOT NULL 
  AND c.product_category_name IS NULL;
GO