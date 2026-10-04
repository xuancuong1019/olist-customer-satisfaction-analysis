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
SELECT TABLE_SCHEMA, TABLE_NAME, COUNT(*) AS column_count
FROM INFORMATION_SCHEMA.COLUMNS
GROUP BY TABLE_SCHEMA, TABLE_NAME
ORDER BY TABLE_SCHEMA, TABLE_NAME;

SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'staging'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- Uniqueness Check
SELECT review_id, COUNT(*) cnt FROM staging.olist_order_reviews GROUP BY review_id HAVING COUNT(*) > 1;

/* Sau khi khảo sát, ở bảng olist_order_reviews có hiện tượng review_id bị trùng lặp. Khi kiểm tra một vài giá trị trùng lặp 
bằng Excel thì phát hiện rằng những giá trị review_id trùng đó có mã order_id khác nhau. Vì Olist là một hệ thống tập hợp 
nhiều cửa hàng, khi một khách hàng mua nhiều đơn hàng cùng một lúc, hệ thống Olist sẽ chỉ khảo sát người dùng bằng một đơn 
duy nhất (cùng một review_id cho các đơn hàng)*/

SELECT review_id, order_id, COUNT(*) as so_lan_lap
FROM staging.olist_order_reviews
GROUP BY review_id,  order_id
HAVING COUNT(*) > 1;

/* Phương hướng xử lý là giữ nguyên chứ không drop, vì đây là dữ liệu thực tế. Sẽ lấy tập hợp review_id và order_id để 
làm khóa chính, nhưng vẫn phải kiểm tra tính độc nhất của tập hợp này */

SELECT order_id, COUNT(*) cnt FROM staging.olist_orders GROUP BY order_id HAVING COUNT(*) > 1;
SELECT customer_id, COUNT(*) cnt FROM staging.olist_customers GROUP BY customer_id HAVING COUNT(*) > 1;
SELECT seller_id, COUNT(*) cnt FROM staging.olist_sellers GROUP BY seller_id HAVING COUNT(*) > 1;
SELECT product_id, COUNT(*) cnt FROM staging.olist_products GROUP BY product_id HAVING COUNT(*) > 1;



-- Completeness / NULL Check
SELECT 'olist_customers' AS table_name, 'customer_id (PK)' AS column_name, COUNT(*) AS null_count 
FROM staging.olist_customers WHERE customer_id IS NULL
UNION ALL
SELECT 'olist_customers', 'customer_unique_id', COUNT(*) 
FROM staging.olist_customers WHERE customer_unique_id IS NULL

UNION ALL
SELECT 'olist_sellers', 'seller_id (PK)', COUNT(*) 
FROM staging.olist_sellers WHERE seller_id IS NULL

UNION ALL
SELECT 'olist_orders', 'order_id (PK)', COUNT(*) 
FROM staging.olist_orders WHERE order_id IS NULL
UNION ALL
SELECT 'olist_orders', 'customer_id (FK)', COUNT(*) 
FROM staging.olist_orders WHERE customer_id IS NULL

UNION ALL
SELECT 'olist_order_items', 'order_id (FK)', COUNT(*) 
FROM staging.olist_order_items WHERE order_id IS NULL
UNION ALL
SELECT 'olist_order_items', 'product_id (FK)', COUNT(*) 
FROM staging.olist_order_items WHERE product_id IS NULL
UNION ALL
SELECT 'olist_order_items', 'seller_id (FK)', COUNT(*) 
FROM staging.olist_order_items WHERE seller_id IS NULL
UNION ALL
SELECT 'olist_order_items', 'price (Metric)', COUNT(*) 
FROM staging.olist_order_items WHERE price IS NULL
UNION ALL
SELECT 'olist_order_items', 'freight_value (Metric)', COUNT(*) 
FROM staging.olist_order_items WHERE freight_value IS NULL

UNION ALL
SELECT 'olist_order_payments', 'order_id (FK)', COUNT(*) 
FROM staging.olist_order_payments WHERE order_id IS NULL
UNION ALL
SELECT 'olist_order_payments', 'payment_value (Metric)', COUNT(*) 
FROM staging.olist_order_payments WHERE payment_value IS NULL

UNION ALL
SELECT 'olist_order_reviews', 'review_id (PK)', COUNT(*) 
FROM staging.olist_order_reviews WHERE review_id IS NULL
UNION ALL
SELECT 'olist_order_reviews', 'order_id (FK)', COUNT(*) 
FROM staging.olist_order_reviews WHERE order_id IS NULL
UNION ALL
SELECT 'olist_order_reviews', 'review_score (Metric)', COUNT(*) 
FROM staging.olist_order_reviews WHERE review_score IS NULL

UNION ALL
SELECT 'olist_products', 'product_id (PK)', COUNT(*) 
FROM staging.olist_products WHERE product_id IS NULL

UNION ALL
SELECT 'product_category', 'product_category_name', COUNT(*) 
FROM staging.product_category WHERE product_category_name IS NULL;


/* Xác nhận được rằng các cột quan trọng đã được kiểm tra missing */

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