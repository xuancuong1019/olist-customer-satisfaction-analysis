/* =========================================================
   3. TRANSFORM & LOAD DATA (STAGING -> CLEANING)
   Business Purpose:
       - Chuẩn hóa chuỗi rỗng ('') thành NULL bằng NULLIF & LTRIM/RTRIM.
       - Ép kiểu dữ liệu chuẩn xác (Xử lý số mũ 'e' ở bảng Geolocation).
       - Bổ sung (Inject) 2 danh mục sản phẩm thiếu bản dịch tiếng Anh.
       - Đổ dữ liệu theo gói giao dịch (Transaction) đảm bảo tính toàn vẹn.
   ========================================================= */

BEGIN TRY
    BEGIN TRANSACTION;

    
    -- 3.1 LOAD: cleaning.olist_geolocation                        
    INSERT INTO cleaning.olist_geolocation (
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    )
    SELECT
        NULLIF(LTRIM(RTRIM(geolocation_zip_code_prefix)), '')                   AS geolocation_zip_code_prefix,
        TRY_CONVERT(
            DECIMAL(22,18),
            TRY_CONVERT(FLOAT, NULLIF(LTRIM(RTRIM(geolocation_lat)), ''))
        )                                                                       AS geolocation_lat,
        TRY_CONVERT(
            DECIMAL(22,18),
            TRY_CONVERT(FLOAT, NULLIF(LTRIM(RTRIM(geolocation_lng)), ''))
        )                                                                       AS geolocation_lng,
        NULLIF(LTRIM(RTRIM(geolocation_city)), '')                              AS geolocation_city,
        NULLIF(LTRIM(RTRIM(geolocation_state)), '')                             AS geolocation_state
    FROM staging.olist_geolocation;


    -- 3.2 LOAD: cleaning.olist_customers 
    INSERT INTO cleaning.olist_customers (
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    )
    SELECT
        NULLIF(LTRIM(RTRIM(customer_id)), '')                                   AS customer_id,
        NULLIF(LTRIM(RTRIM(customer_unique_id)), '')                            AS customer_unique_id,
        NULLIF(LTRIM(RTRIM(customer_zip_code_prefix)), '')                      AS customer_zip_code_prefix,
        NULLIF(LTRIM(RTRIM(customer_city)), '')                                 AS customer_city,
        NULLIF(LTRIM(RTRIM(customer_state)), '')                                AS customer_state
    FROM staging.olist_customers;


    -- 3.3 LOAD: cleaning.olist_sellers 
    INSERT INTO cleaning.olist_sellers (
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    )
    SELECT
        NULLIF(LTRIM(RTRIM(seller_id)), '')                                     AS seller_id,
        NULLIF(LTRIM(RTRIM(seller_zip_code_prefix)), '')                        AS seller_zip_code_prefix,
        NULLIF(LTRIM(RTRIM(seller_city)), '')                                   AS seller_city,
        NULLIF(LTRIM(RTRIM(seller_state)), '')                                  AS seller_state
    FROM staging.olist_sellers;


    -- 3.4 LOAD: cleaning.product_category_name_translation               │
    -- Note: Bổ sung 2 danh mục thiếu trong bảng từ điển gốc của Olist 
    INSERT INTO cleaning.product_category_name_translation (
        product_category_name,
        product_category_name_english
    )
    SELECT
        NULLIF(LTRIM(RTRIM(product_category_name)), '')                         AS product_category_name,
        NULLIF(LTRIM(RTRIM(product_category_name_english)), '')                 AS product_category_name_english
    FROM staging.product_category_name_translation;

    -- Inject 2 danh mục tiếng Bồ Đào Nha bị thiếu để đảm bảo toàn vẹn FK
    INSERT INTO cleaning.product_category_name_translation (
        product_category_name,
        product_category_name_english
    )
    SELECT v.product_category_name, v.product_category_name_english
    FROM (
        VALUES
            ('pc_gamer', 'pc_gamer'),
            ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_food_preparers')
    ) AS v(product_category_name, product_category_name_english)
    WHERE NOT EXISTS (
        SELECT 1
        FROM cleaning.product_category_name_translation t
        WHERE t.product_category_name = v.product_category_name
    );


    -- 3.5 LOAD: cleaning.olist_products 
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
        NULLIF(LTRIM(RTRIM(product_id)), '')                                    AS product_id,
        NULLIF(LTRIM(RTRIM(product_category_name)), '')                         AS product_category_name,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_name_lenght)), ''))         AS product_name_lenght,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_description_lenght)), ''))  AS product_description_lenght,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_photos_qty)), ''))          AS product_photos_qty,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_weight_g)), ''))            AS product_weight_g,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_length_cm)), ''))           AS product_length_cm,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_height_cm)), ''))           AS product_height_cm,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(product_width_cm)), ''))            AS product_width_cm
    FROM staging.olist_products;


    -- 3.6 LOAD: cleaning.olist_orders  
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
        NULLIF(LTRIM(RTRIM(order_id)), '')                                      AS order_id,
        NULLIF(LTRIM(RTRIM(customer_id)), '')                                   AS customer_id,
        NULLIF(LTRIM(RTRIM(order_status)), '')                                  AS order_status,
        TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_purchase_timestamp)), ''), 120)      AS order_purchase_timestamp,
        TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_approved_at)), ''), 120)             AS order_approved_at,
        TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)), ''), 120)  AS order_delivered_carrier_date,
        TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), ''), 120) AS order_delivered_customer_date,
        TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), ''), 120) AS order_estimated_delivery_date
    FROM staging.olist_orders;


    -- 3.7 LOAD: cleaning.olist_order_items      
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
        NULLIF(LTRIM(RTRIM(order_id)), '')                                      AS order_id,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(order_item_id)), ''))               AS order_item_id,
        NULLIF(LTRIM(RTRIM(product_id)), '')                                    AS product_id,
        NULLIF(LTRIM(RTRIM(seller_id)), '')                                     AS seller_id,
        TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(shipping_limit_date)), ''), 120) AS shipping_limit_date,
        TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM(price)), ''))             AS price,
        TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM(freight_value)), ''))     AS freight_value
    FROM staging.olist_order_items;


    -- 3.8 LOAD: cleaning.olist_order_payments  
    INSERT INTO cleaning.olist_order_payments (
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
    )
    SELECT
        NULLIF(LTRIM(RTRIM(order_id)), '')                                      AS order_id,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(payment_sequential)), ''))          AS payment_sequential,
        NULLIF(LTRIM(RTRIM(payment_type)), '')                                  AS payment_type,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(payment_installments)), ''))        AS payment_installments,
        TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM(payment_value)), ''))     AS payment_value
    FROM staging.olist_order_payments;


    -- 3.9 LOAD: cleaning.olist_order_reviews   
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
        NULLIF(LTRIM(RTRIM(review_id)), '')                                     AS review_id,
        NULLIF(LTRIM(RTRIM(order_id)), '')                                      AS order_id,
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(review_score)), ''))                AS review_score,
        NULLIF(LTRIM(RTRIM(review_comment_title)), '')                          AS review_comment_title,
        NULLIF(LTRIM(RTRIM(review_comment_message)), '')                        AS review_comment_message,
        TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(review_creation_date)), ''), 120)    AS review_creation_date,
        TRY_CONVERT(DATETIME2(0), NULLIF(LTRIM(RTRIM(review_answer_timestamp)), ''), 120) AS review_answer_timestamp
    FROM staging.olist_order_reviews;


    COMMIT TRANSACTION;
    PRINT 'SUCCESS: All data transformed and loaded into [cleaning] schema.';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO