/* ==============================================================================
   PROJECT     : OLIST E-COMMERCE ANALYTICS
   SCRIPT NAME : 06_add_foreign_keys.sql
   PURPOSE     : Thiết lập toàn bộ Ràng buộc Khóa ngoại (Foreign Keys) cho các 
                 bảng trong schema [cleaning] sau khi đã hoàn tất nạp dữ liệu.
   NOTE        : Các Primary Keys (PK) đã được khởi tạo trước ở script 02.
   ============================================================================== */

USE e_commerce;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;


-- ==============================================================================
-- SECTION 1: APPLY FOREIGN KEY CONSTRAINTS (Thiết lập Khóa ngoại)
-- ==============================================================================
/* Business Purpose: Khóa chặt tính toàn vẹn tham chiếu (Referential Integrity) 
   giữa các bảng Fact (Orders, Items, Payments, Reviews) và Dimension (Customers, 
   Products, Sellers, Category Translation) để tối ưu hóa Execution Plan khi JOIN. */

BEGIN TRY
    BEGIN TRANSACTION;

    -- ┌────────────────────────────────────────────────────────────────────────┐
    -- │ 1.1 Bảng: cleaning.olist_orders                                        │
    -- │ Tham chiếu: customer_id -> cleaning.olist_customers(customer_id)       │
    -- └────────────────────────────────────────────────────────────────────────┘
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_orders_customers')
    BEGIN
        ALTER TABLE cleaning.olist_orders WITH CHECK
        ADD CONSTRAINT FK_orders_customers
            FOREIGN KEY (customer_id)
            REFERENCES cleaning.olist_customers (customer_id);
    END;


    -- ┌────────────────────────────────────────────────────────────────────────┐
    -- │ 1.2 Bảng: cleaning.olist_products                                      │
    -- │ Tham chiếu: product_category_name -> product_category_name_translation │
    -- └────────────────────────────────────────────────────────────────────────┘
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_products_category_translation')
    BEGIN
        ALTER TABLE cleaning.olist_products WITH CHECK
        ADD CONSTRAINT FK_products_category_translation
            FOREIGN KEY (product_category_name)
            REFERENCES cleaning.product_category_name_translation (product_category_name);
    END;


    -- ┌────────────────────────────────────────────────────────────────────────┐
    -- │ 1.3 Bảng: cleaning.olist_order_items (3 Foreign Keys)                  │
    -- │ Tham chiếu:                                                            │
    -- │   - order_id   -> cleaning.olist_orders(order_id)                      │
    -- │   - product_id -> cleaning.olist_products(product_id)                  │
    -- │   - seller_id  -> cleaning.olist_sellers(seller_id)                    │
    -- └────────────────────────────────────────────────────────────────────────┘
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_order_items_orders')
    BEGIN
        ALTER TABLE cleaning.olist_order_items WITH CHECK
        ADD CONSTRAINT FK_order_items_orders
            FOREIGN KEY (order_id)
            REFERENCES cleaning.olist_orders (order_id);
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_order_items_products')
    BEGIN
        ALTER TABLE cleaning.olist_order_items WITH CHECK
        ADD CONSTRAINT FK_order_items_products
            FOREIGN KEY (product_id)
            REFERENCES cleaning.olist_products (product_id);
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_order_items_sellers')
    BEGIN
        ALTER TABLE cleaning.olist_order_items WITH CHECK
        ADD CONSTRAINT FK_order_items_sellers
            FOREIGN KEY (seller_id)
            REFERENCES cleaning.olist_sellers (seller_id);
    END;


    -- ┌────────────────────────────────────────────────────────────────────────┐
    -- │ 1.4 Bảng: cleaning.olist_order_payments                                │
    -- │ Tham chiếu: order_id -> cleaning.olist_orders(order_id)                │
    -- └────────────────────────────────────────────────────────────────────────┘
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_order_payments_orders')
    BEGIN
        ALTER TABLE cleaning.olist_order_payments WITH CHECK
        ADD CONSTRAINT FK_order_payments_orders
            FOREIGN KEY (order_id)
            REFERENCES cleaning.olist_orders (order_id);
    END;


    -- ┌────────────────────────────────────────────────────────────────────────┐
    -- │ 1.5 Bảng: cleaning.olist_order_reviews                                 │
    -- │ Tham chiếu: order_id -> cleaning.olist_orders(order_id)                │
    -- └────────────────────────────────────────────────────────────────────────┘
    IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_order_reviews_orders')
    BEGIN
        ALTER TABLE cleaning.olist_order_reviews WITH CHECK
        ADD CONSTRAINT FK_order_reviews_orders
            FOREIGN KEY (order_id)
            REFERENCES cleaning.olist_orders (order_id);
    END;

    /* ==========================================================================
       LƯU Ý KIẾN TRÚC VỀ BẢNG OLIST_SELLERS & OLIST_GEOLOCATION:
       - Không thể chạy lệnh:
         ALTER TABLE cleaning.olist_sellers ADD CONSTRAINT FK_sellers_geolocation 
         FOREIGN KEY (seller_zip_code_prefix) REFERENCES cleaning.olist_geolocation(geolocation_zip_code_prefix)
       - Lý do:1. Bảng [olist_geolocation] không có PK/Unique Key trên cột zip_code_prefix.
               2. Trong dữ liệu gốc Olist, có 7 seller_zip_code_prefix (và gần 300 
                  customer_zip_code_prefix) KHÔNG tồn tại trong bảng olist_geolocation.
       - Giải pháp chuẩn: Giữ mối quan hệ Logic (Logical Relationship) khi JOIN hoặc 
         trong Power BI, không áp đặt Physical FK cho Geolocation.
       ========================================================================== */

    COMMIT TRANSACTION;
    PRINT '✅ SECTION 1 PASSED: All 7 core Foreign Keys have been successfully created.';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO


-- ==============================================================================
-- SECTION 2: VERIFY CREATED FOREIGN KEYS (Kiểm tra danh sách FK vừa tạo)
-- ==============================================================================
/* Business Question: Các ràng buộc Khóa ngoại đã được kích hoạt (is_enabled = 1) 
   và được SQL Server xác thực hoàn toàn (is_not_trusted = 0) hay chưa? */

SELECT 
    fk.name                                     AS foreign_key_name,
    SCHEMA_NAME(tp.schema_id) + '.' + tp.name   AS parent_table,
    cp.name                                     AS parent_column,
    SCHEMA_NAME(tr.schema_id) + '.' + tr.name   AS referenced_table,
    cr.name                                     AS referenced_column,
    fk.is_disabled,
    fk.is_not_trusted
FROM sys.foreign_keys fk
INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
INNER JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
INNER JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
INNER JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
WHERE SCHEMA_NAME(tp.schema_id) = 'cleaning'
ORDER BY parent_table, foreign_key_name;
GO