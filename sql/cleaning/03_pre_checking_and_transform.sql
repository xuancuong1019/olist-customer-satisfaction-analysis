/* ==============================================================================
   PROJECT     : OLIST E-COMMERCE ANALYTICS
   SCRIPT NAME : 03_pre_checking_and_transform.sql
   PURPOSE     : 
       1. Pre-check: Đảm bảo các bảng đích trong schema [cleaning] đang trống.
       2. Validation: Quét toàn bộ lỗi ép kiểu (Numeric & Datetime) từ [staging].
       3. Transform Dry-Run: Kiểm thử công thức xử lý ký tự khoa học ('e') và 
          xác nhận các danh mục sản phẩm bị thiếu bản dịch tiếng Anh trước khi Load.
   ============================================================================== */

USE e_commerce;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;


-- ==============================================================================
-- SECTION 1: PRE-CHECK DESTINATION TABLES (Đảm bảo bảng đích trống trước khi nạp)
-- ==============================================================================
/* Business Question: Các bảng trong schema [cleaning] đã sẵn sàng (trống) để 
   nhận dữ liệu mới chưa, nhằm tránh nhân đôi dữ liệu (duplicate load)? */

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
    THROW 51000, 'ABORT: Cleaning tables are not empty. Truncate or check existing data before loading.', 1;
END;
PRINT '✅ SECTION 1 PASSED: All destination tables in [cleaning] are empty.';
GO


-- ==============================================================================
-- SECTION 2: DATA TYPE CONVERSION VALIDATION (Kiểm tra lỗi ép kiểu dữ liệu)
-- ==============================================================================
/* Business Question: Có giá trị khác rỗng (non-blank) nào trong tầng [staging] 
   không thể chuyển đổi sang kiểu dữ liệu chuẩn của tầng [cleaning] hay không? */

DROP TABLE IF EXISTS #ConversionErrors;

CREATE TABLE #ConversionErrors (
    source_table  VARCHAR(100),
    column_name   VARCHAR(100),
    invalid_value NVARCHAR(4000)
);

INSERT INTO #ConversionErrors (source_table, column_name, invalid_value)

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ 2.1 Bảng: staging.olist_geolocation                                        │
-- │ Lưu ý: Ép qua FLOAT trước để hỗ trợ định dạng số khoa học (chứa ký tự 'e') │
-- └────────────────────────────────────────────────────────────────────────────┘
SELECT 'staging.olist_geolocation', 'geolocation_lat', CONVERT(NVARCHAR(4000), geolocation_lat)
FROM staging.olist_geolocation
WHERE NULLIF(LTRIM(RTRIM(geolocation_lat)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(22,18), TRY_CONVERT(FLOAT, NULLIF(LTRIM(RTRIM(geolocation_lat)), ''))) IS NULL
UNION ALL
SELECT 'staging.olist_geolocation', 'geolocation_lng', CONVERT(NVARCHAR(4000), geolocation_lng)
FROM staging.olist_geolocation
WHERE NULLIF(LTRIM(RTRIM(geolocation_lng)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(22,18), TRY_CONVERT(FLOAT, NULLIF(LTRIM(RTRIM(geolocation_lng)), ''))) IS NULL

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ 2.2 Bảng: staging.olist_products                                           │
-- └────────────────────────────────────────────────────────────────────────────┘
UNION ALL
SELECT 'staging.olist_products', 'product_name_lenght', CONVERT(NVARCHAR(4000), product_name_lenght)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_name_lenght)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_name_lenght)), '')) IS NULL
UNION ALL
SELECT 'staging.olist_products', 'product_description_lenght', CONVERT(NVARCHAR(4000), product_description_lenght)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_description_lenght)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_description_lenght)), '')) IS NULL
UNION ALL
SELECT 'staging.olist_products', 'product_photos_qty', CONVERT(NVARCHAR(4000), product_photos_qty)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_photos_qty)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_photos_qty)), '')) IS NULL
UNION ALL
SELECT 'staging.olist_products', 'product_weight_g', CONVERT(NVARCHAR(4000), product_weight_g)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_weight_g)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_weight_g)), '')) IS NULL
UNION ALL
SELECT 'staging.olist_products', 'product_length_cm', CONVERT(NVARCHAR(4000), product_length_cm)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_length_cm)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_length_cm)), '')) IS NULL
UNION ALL
SELECT 'staging.olist_products', 'product_height_cm', CONVERT(NVARCHAR(4000), product_height_cm)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_height_cm)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_height_cm)), '')) IS NULL
UNION ALL
SELECT 'staging.olist_products', 'product_width_cm', CONVERT(NVARCHAR(4000), product_width_cm)
FROM staging.olist_products
WHERE NULLIF(LTRIM(RTRIM(product_width_cm)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_width_cm)), '')) IS NULL

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ 2.3 Bảng: staging.olist_orders (Kiểm tra định dạng DATETIME2 chuẩn 120)    │
-- └────────────────────────────────────────────────────────────────────────────┘
UNION ALL
SELECT 'staging.olist_orders', 'order_purchase_timestamp', CONVERT(NVARCHAR(4000), order_purchase_timestamp)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_purchase_timestamp)), '') IS NOT NULL
  AND TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_purchase_timestamp)), ''), 120) IS NULL
UNION ALL
SELECT 'staging.olist_orders', 'order_approved_at', CONVERT(NVARCHAR(4000), order_approved_at)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_approved_at)), '') IS NOT NULL
  AND TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_approved_at)), ''), 120) IS NULL
UNION ALL
SELECT 'staging.olist_orders', 'order_delivered_carrier_date', CONVERT(NVARCHAR(4000), order_delivered_carrier_date)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)), '') IS NOT NULL
  AND TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)), ''), 120) IS NULL
UNION ALL
SELECT 'staging.olist_orders', 'order_delivered_customer_date', CONVERT(NVARCHAR(4000), order_delivered_customer_date)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), '') IS NOT NULL
  AND TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), ''), 120) IS NULL
UNION ALL
SELECT 'staging.olist_orders', 'order_estimated_delivery_date', CONVERT(NVARCHAR(4000), order_estimated_delivery_date)
FROM staging.olist_orders
WHERE NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), '') IS NOT NULL
  AND TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), ''), 120) IS NULL

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ 2.4 Bảng: staging.olist_order_items                                        │
-- └────────────────────────────────────────────────────────────────────────────┘
UNION ALL
SELECT 'staging.olist_order_items', 'order_item_id', CONVERT(NVARCHAR(4000), order_item_id)
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(order_item_id)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(order_item_id)), '')) IS NULL
UNION ALL
SELECT 'staging.olist_order_items', 'shipping_limit_date', CONVERT(NVARCHAR(4000), shipping_limit_date)
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(shipping_limit_date)), '') IS NOT NULL
  AND TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(shipping_limit_date)), ''), 120) IS NULL
UNION ALL
SELECT 'staging.olist_order_items', 'price', CONVERT(NVARCHAR(4000), price)
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(price)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM(price)), '')) IS NULL
UNION ALL
SELECT 'staging.olist_order_items', 'freight_value', CONVERT(NVARCHAR(4000), freight_value)
FROM staging.olist_order_items
WHERE NULLIF(LTRIM(RTRIM(freight_value)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM(freight_value)), '')) IS NULL

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ 2.5 Bảng: staging.olist_order_payments                                     │
-- └────────────────────────────────────────────────────────────────────────────┘
UNION ALL
SELECT 'staging.olist_order_payments', 'payment_sequential', CONVERT(NVARCHAR(4000), payment_sequential)
FROM staging.olist_order_payments
WHERE NULLIF(LTRIM(RTRIM(payment_sequential)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(payment_sequential)), '')) IS NULL
UNION ALL
SELECT 'staging.olist_order_payments', 'payment_installments', CONVERT(NVARCHAR(4000), payment_installments)
FROM staging.olist_order_payments
WHERE NULLIF(LTRIM(RTRIM(payment_installments)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(payment_installments)), '')) IS NULL
UNION ALL
SELECT 'staging.olist_order_payments', 'payment_value', CONVERT(NVARCHAR(4000), payment_value)
FROM staging.olist_order_payments
WHERE NULLIF(LTRIM(RTRIM(payment_value)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM(payment_value)), '')) IS NULL

-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │ 2.6 Bảng: staging.olist_order_reviews                                      │
-- └────────────────────────────────────────────────────────────────────────────┘
UNION ALL
SELECT 'staging.olist_order_reviews', 'review_score', CONVERT(NVARCHAR(4000), review_score)
FROM staging.olist_order_reviews
WHERE NULLIF(LTRIM(RTRIM(review_score)), '') IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(review_score)), '')) IS NULL
UNION ALL
SELECT 'staging.olist_order_reviews', 'review_creation_date', CONVERT(NVARCHAR(4000), review_creation_date)
FROM staging.olist_order_reviews
WHERE NULLIF(LTRIM(RTRIM(review_creation_date)), '') IS NOT NULL
  AND TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(review_creation_date)), ''), 120) IS NULL
UNION ALL
SELECT 'staging.olist_order_reviews', 'review_answer_timestamp', CONVERT(NVARCHAR(4000), review_answer_timestamp)
FROM staging.olist_order_reviews
WHERE NULLIF(LTRIM(RTRIM(review_answer_timestamp)), '') IS NOT NULL
  AND TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(review_answer_timestamp)), ''), 120) IS NULL;


-- Kiểm tra và chặn đứng nếu phát sinh lỗi ép kiểu chưa được xử lý
IF EXISTS (SELECT 1 FROM #ConversionErrors)
BEGIN
    SELECT 
        source_table, 
        column_name, 
        invalid_value
    FROM #ConversionErrors
    ORDER BY source_table, column_name;

    DROP TABLE IF EXISTS #ConversionErrors;

    THROW 51001, 'ABORT: Invalid numeric or datetime values found. Review the result set before loading.', 1;
END;

DROP TABLE IF EXISTS #ConversionErrors;
PRINT '✅ SECTION 2 PASSED: Zero conversion errors detected across all staging tables.';
GO


-- ==============================================================================
-- SECTION 3: TRANSFORMATION DRY-RUN & EDGE-CASE VERIFICATION
-- ==============================================================================
/* Business Purpose: 
   Lưu vết và kiểm thử trực tiếp 2 trường hợp ngoại lệ đã phát hiện trong quá trình
   khảo sát dữ liệu trước khi thực thi script 04_import_cleaned_data.sql:
   1. Hằng số khoa học ('e') trong cột tọa độ bảng Geolocation.
   2. Các danh mục sản phẩm (product_category_name) bị thiếu trong bảng Translation. */

-- 3.1 Kiểm thử chuyển đổi tọa độ chứa ký tự khoa học ('e') sang DECIMAL(22,18)
SELECT 
    geolocation_zip_code_prefix,
    geolocation_lat                                                         AS raw_string_lat,
    TRY_CONVERT(FLOAT, NULLIF(LTRIM(RTRIM(geolocation_lat)), ''))           AS intermediate_float,
    TRY_CONVERT(
        DECIMAL(22,18), 
        TRY_CONVERT(FLOAT, NULLIF(LTRIM(RTRIM(geolocation_lat)), ''))
    )                                                                       AS final_decimal_lat
FROM staging.olist_geolocation
WHERE geolocation_lat LIKE '%e%' 
   OR geolocation_lng LIKE '%e%';

-- 3.2 Kiểm tra các danh mục trong bảng Products chưa có mặt trong bảng Translation
SELECT DISTINCT 
    NULLIF(LTRIM(RTRIM(p.product_category_name)), '')                       AS missing_category_in_translation,
    COUNT(*)                                                                AS affected_products_count
FROM staging.olist_products p
LEFT JOIN staging.product_category_name_translation t 
    ON NULLIF(LTRIM(RTRIM(p.product_category_name)), '') = NULLIF(LTRIM(RTRIM(t.product_category_name)), '')
WHERE NULLIF(LTRIM(RTRIM(p.product_category_name)), '') IS NOT NULL 
  AND t.product_category_name IS NULL
GROUP BY NULLIF(LTRIM(RTRIM(p.product_category_name)), '');

PRINT '✅ SECTION 3 COMPLETED: Transformation rules verified. Ready to run 04_import_cleaned_data.sql.';
GO