/* Investigating missing values in order_approved_at*/
SELECT *
FROM staging.olist_orders
WHERE order_status = 'delivered'
  AND order_approved_at IS NULL;


/* Sau khi xác định 14 đơn hàng có trạng thái delivered nhưng bị thiếu giá trị ở order_approved_at, 
tôi nhận thấy một điểm bất thường đáng chú ý: ngày giao hàng (order_delivered_customer_date) của cả 
14 đơn hàng đều nằm trong khoảng từ ngày 17/02/2017 đến 19/02/2017 và có 2 đơn trong ngày 19/1/2017 */

/* Trong quá trình kiểm tra chất lượng dữ liệu, phát hiện 14 đơn hàng có trạng thái delivered và thiếu order_approved_at. 
đều sử dụng phương thức thanh toán boleto. Cần tiếp tục kiểm tra tỷ lệ thiếu dữ liệu trong nhóm đơn boleto 
và đối chiếu các mốc thời gian để xác định liệu đây là vấn đề mang tính hệ thống hay một nhóm dữ liệu bất thường riêng biệt.
*/


SELECT
    CASE
        WHEN order_approved_at IS NULL
             OR TRIM(order_approved_at) = ''
        THEN 'Missing'
        ELSE 'Not Missing'
    END AS approval_status,
    COUNT(*) AS total_orders
FROM staging.olist_orders AS o
WHERE order_status = 'delivered'
  AND EXISTS (
      SELECT 1
      FROM staging.olist_order_payments AS p
      WHERE p.order_id = o.order_id
        AND p.payment_type = 'boleto'
  )
GROUP BY
    CASE
        WHEN order_approved_at IS NULL
             OR TRIM(order_approved_at) = ''
        THEN 'Missing'
        ELSE 'Not Missing'
    END;
 

SELECT
    p.payment_type,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE
        WHEN o.order_approved_at IS NULL
          OR TRIM(o.order_approved_at) = ''
        THEN o.order_id
    END) AS missing_orders,
    CAST(
        100.0 * COUNT(DISTINCT CASE
            WHEN o.order_approved_at IS NULL
              OR TRIM(o.order_approved_at) = ''
            THEN o.order_id
        END)
        / NULLIF(COUNT(DISTINCT o.order_id), 0)
        AS DECIMAL(10, 4)
    ) AS missing_rate_pct
FROM staging.olist_orders AS o
JOIN staging.olist_order_payments AS p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.payment_type
ORDER BY missing_rate_pct DESC;

SELECT
    CAST(o.order_purchase_timestamp AS DATE) AS purchase_date,
    p.payment_type,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE
        WHEN o.order_approved_at IS NULL
          OR TRIM(o.order_approved_at) = ''
        THEN o.order_id
    END) AS missing_orders
FROM staging.olist_orders AS o
JOIN staging.olist_order_payments AS p
    ON o.order_id = p.order_id
WHERE CAST(o.order_purchase_timestamp AS DATE)
      BETWEEN '2017-02-17' AND '2017-02-19'
GROUP BY
    CAST(o.order_purchase_timestamp AS DATE),
    p.payment_type
ORDER BY
    purchase_date,
    p.payment_type;


SELECT
    CAST(o.order_purchase_timestamp AS DATE) AS purchase_date,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE
        WHEN o.order_approved_at IS NULL
          OR TRIM(o.order_approved_at) = ''
        THEN o.order_id
    END) AS missing_orders
FROM staging.olist_orders AS o
WHERE o.order_status = 'delivered'
  AND EXISTS (
      SELECT 1
      FROM staging.olist_order_payments AS p
      WHERE p.order_id = o.order_id
        AND p.payment_type = 'boleto'
  )
  AND CAST(o.order_purchase_timestamp AS DATE) IN (
      '2017-01-19',
      '2017-02-17',
      '2017-02-18',
      '2017-02-19'
  )
GROUP BY CAST(o.order_purchase_timestamp AS DATE)
ORDER BY purchase_date;




