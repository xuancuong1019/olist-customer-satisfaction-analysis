SELECT 'olist_customers' AS table_name, COUNT(*) AS row_count FROM staging.olist_customers
UNION ALL
SELECT 'olist_sellers', COUNT(*) FROM staging.olist_sellers
UNION ALL
SELECT 'olist_geolocation', COUNT(*) FROM staging.olist_geolocation
UNION ALL
SELECT 'product_category', COUNT(*) FROM staging.product_category
UNION ALL
SELECT 'olist_products', COUNT(*) FROM staging.olist_products
UNION ALL
SELECT 'olist_orders', COUNT(*) FROM staging.olist_orders
UNION ALL
SELECT 'olist_order_items', COUNT(*) FROM staging.olist_order_items
UNION ALL
SELECT 'olist_order_payments', COUNT(*) FROM staging.olist_order_payments
UNION ALL
SELECT 'olist_order_reviews', COUNT(*) FROM staging.olist_order_reviews;