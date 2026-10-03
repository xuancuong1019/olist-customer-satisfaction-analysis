SELECT 'olist_customers' AS t, COUNT(*) AS cnt FROM staging.olist_customers
UNION ALL SELECT 'olist_sellers', COUNT(*) FROM staging.olist_sellers
UNION ALL SELECT 'olist_geolocation', COUNT(*) FROM staging.olist_geolocation
UNION ALL SELECT 'product_category', COUNT(*) FROM staging.product_category
UNION ALL SELECT 'olist_products', COUNT(*) FROM staging.olist_products
UNION ALL SELECT 'olist_orders', COUNT(*) FROM staging.olist_orders
UNION ALL SELECT 'olist_order_items', COUNT(*) FROM staging.olist_order_items
UNION ALL SELECT 'olist_order_payments', COUNT(*) FROM staging.olist_order_payments
UNION ALL SELECT 'olist_order_reviews', COUNT(*) FROM staging.olist_order_reviews;

-- 2. Trùng khóa chính dự kiến
SELECT review_id, COUNT(*) cnt FROM staging.olist_order_reviews GROUP BY review_id HAVING COUNT(*) > 1;
SELECT order_id, COUNT(*) cnt FROM staging.olist_orders GROUP BY order_id HAVING COUNT(*) > 1;
SELECT customer_id, COUNT(*) cnt FROM staging.olist_customers GROUP BY customer_id HAVING COUNT(*) > 1;

SELECT review_id, order_id, COUNT(*) AS cnt
FROM staging.olist_order_reviews
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;

-- 3. customer_id vs customer_unique_id (vấn đề đã cảnh báo)
SELECT COUNT(DISTINCT customer_id) AS total_customer_id,
       COUNT(DISTINCT customer_unique_id) AS total_unique_customer
FROM staging.olist_customers;

-- 4. Orphan FK
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

