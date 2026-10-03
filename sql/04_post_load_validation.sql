-- Volume / Row Count Check
SELECT 'olist_customers' AS t, COUNT(*) AS cnt FROM staging.olist_customers
UNION ALL SELECT 'olist_sellers', COUNT(*) FROM staging.olist_sellers
UNION ALL SELECT 'olist_geolocation', COUNT(*) FROM staging.olist_geolocation
UNION ALL SELECT 'product_category', COUNT(*) FROM staging.product_category
UNION ALL SELECT 'olist_products', COUNT(*) FROM staging.olist_products
UNION ALL SELECT 'olist_orders', COUNT(*) FROM staging.olist_orders
UNION ALL SELECT 'olist_order_items', COUNT(*) FROM staging.olist_order_items
UNION ALL SELECT 'olist_order_payments', COUNT(*) FROM staging.olist_order_payments
UNION ALL SELECT 'olist_order_reviews', COUNT(*) FROM staging.olist_order_reviews;

-- Uniqueness Check
SELECT review_id, COUNT(*) cnt FROM staging.olist_order_reviews GROUP BY review_id HAVING COUNT(*) > 1;

/* Sau khi khảo sát, ở bảng olist_order_reviews co hiện tượng review_id bị trùng lặp. Khi kiểm tra một vài giá trị trùng lặp 
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

-- Business Logic Check






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



-- Referential Integrity Check
SELECT COUNT(*) AS orphan_items FROM staging.olist_order_items oi
LEFT JOIN staging.olist_orders o ON oi.order_id = o.order_id WHERE o.order_id IS NULL;

SELECT COUNT(*) AS orphan_orders FROM staging.olist_orders o
LEFT JOIN staging.olist_customers c ON o.customer_id = c.customer_id WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS orphan_reviews FROM staging.olist_order_reviews r
LEFT JOIN staging.olist_orders o ON r.order_id = o.order_id WHERE o.order_id IS NULL;

-- 5. Kiểm tra convert kiểu dữ liệu (chuẩn bị cho clean layer)
SELECT COUNT(*) AS bad_date FROM staging.olist_orders
WHERE TRY_CAST(order_purchase_timestamp AS DATETIME2) IS NULL AND order_purchase_timestamp IS NOT NULL;

SELECT review_score, COUNT(*) cnt FROM staging.olist_order_reviews GROUP BY review_score ORDER BY review_score;


-- PK Setting