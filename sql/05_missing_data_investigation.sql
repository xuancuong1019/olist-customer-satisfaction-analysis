/* Investigating missing values in order_approved_at*/
/* 1. Profile missing values in order_approved_at */

SELECT
    order_status,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN NULLIF(TRIM(order_approved_at), '') IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_orders,
    CAST(
        100.0 * SUM(
            CASE
                WHEN NULLIF(TRIM(order_approved_at), '') IS NULL
                THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10, 4)
    ) AS missing_rate_pct
FROM staging.olist_orders
GROUP BY order_status
ORDER BY missing_rate_pct DESC;

/* 2. Compare missing approval timestamps by payment type
   among delivered orders */

WITH order_payment AS (
    SELECT DISTINCT
        order_id,
        payment_type
    FROM staging.olist_order_payments
)
SELECT
    p.payment_type,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE
        WHEN NULLIF(TRIM(o.order_approved_at), '') IS NULL
        THEN o.order_id
    END) AS missing_orders,
    CAST(
        100.0 * COUNT(DISTINCT CASE
            WHEN NULLIF(TRIM(o.order_approved_at), '') IS NULL
            THEN o.order_id
        END)
        / NULLIF(COUNT(DISTINCT o.order_id), 0)
        AS DECIMAL(10, 4)
    ) AS missing_rate_pct
FROM staging.olist_orders AS o
JOIN order_payment AS p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.payment_type
ORDER BY missing_rate_pct DESC;

/* 3. Investigate missing approval timestamps on identified dates */

WITH order_payment AS (
    SELECT DISTINCT
        order_id,
        payment_type
    FROM staging.olist_order_payments
),
orders_normalized AS (
    SELECT
        order_id,
        order_status,
        TRY_CONVERT(
            date,
            NULLIF(TRIM(order_purchase_timestamp), '')
        ) AS purchase_date,
        NULLIF(TRIM(order_approved_at), '') AS approved_at
    FROM staging.olist_orders
)
SELECT
    o.purchase_date,
    p.payment_type,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE
        WHEN o.approved_at IS NULL
        THEN o.order_id
    END) AS missing_orders,
    CAST(
        100.0 * COUNT(DISTINCT CASE
            WHEN o.approved_at IS NULL
            THEN o.order_id
        END)
        / NULLIF(COUNT(DISTINCT o.order_id), 0)
        AS DECIMAL(10, 2)
    ) AS missing_rate_pct
FROM orders_normalized AS o
JOIN order_payment AS p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
  AND o.purchase_date IN (
      CONVERT(date, '20170119', 112),
      CONVERT(date, '20170217', 112),
      CONVERT(date, '20170218', 112),
      CONVERT(date, '20170219', 112)
  )
GROUP BY
    o.purchase_date,
    p.payment_type
ORDER BY
    o.purchase_date,
    p.payment_type;

/* 4. Review anomalous delivered orders */

SELECT
    order_id,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_status
FROM staging.olist_orders
WHERE order_status = 'delivered'
  AND NULLIF(TRIM(order_approved_at), '') IS NULL
ORDER BY order_purchase_timestamp, order_id;


/*Investigating missing values in order_delivered_carrier_date*/

SELECT
    order_status,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN order_delivered_carrier_date IS NULL
              OR TRIM(order_delivered_carrier_date) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_carrier_date
FROM staging.olist_orders
GROUP BY order_status
ORDER BY missing_carrier_date DESC;

/*Sau khi kiểm tra tổng các đơn hàng theo trạng thái thì nhận thấy rằng dữ liệu đúng với thực tế khi các đơn
bị khuyết ngày giao cho đơn vị vận chuyển tập trung ở unavailable, canceled, invoiced và processing. Trong 625 
đơn hàng bị canceled thì chỉ có 550 đơn bị khuyết, nên kiểm tra lại 75 đơn hàng không bị miss 
order_delivered_carrier_date này */

SELECT
    p.payment_type,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM staging.olist_orders AS o
JOIN staging.olist_order_payments AS p
    ON o.order_id = p.order_id
WHERE o.order_status = 'canceled'
  AND NULLIF(TRIM(o.order_delivered_carrier_date), '') IS NOT NULL
GROUP BY p.payment_type
ORDER BY total_orders DESC;

/*Hầu hết là được thanh toán bằng credit_card*/

WITH canceled_orders AS (
    SELECT DISTINCT order_id
    FROM staging.olist_orders
    WHERE order_status = 'canceled'
),
payment_by_order AS (
    SELECT DISTINCT
        order_id,
        payment_type
    FROM staging.olist_order_payments
)
SELECT
    p.payment_type,
    COUNT(DISTINCT o.order_id) AS total_orders,
    CAST(
        100.0 * COUNT(DISTINCT o.order_id)
        / SUM(COUNT(DISTINCT o.order_id)) OVER ()
        AS DECIMAL(5,2)
    ) AS percentage
FROM canceled_orders AS o
JOIN payment_by_order AS p
    ON o.order_id = p.order_id
GROUP BY p.payment_type
ORDER BY total_orders DESC;

/*Trong tổng các đơn hàng có thông tin thanh toán thì credit_card chiếm tỉ lệ cao nhât */

WITH selected_orders AS (
    SELECT
        order_id,
        order_status
    FROM staging.olist_orders
    WHERE order_status IN ('canceled', 'delivered')
      AND NULLIF(
          TRIM(order_delivered_carrier_date), ''
      ) IS NOT NULL
),
payment_by_order AS (
    SELECT DISTINCT
        order_id,
        payment_type
    FROM staging.olist_order_payments
)
SELECT
    o.order_status,
    p.payment_type,
    COUNT(DISTINCT o.order_id) AS total_orders,
    CAST(
        100.0 * COUNT(DISTINCT o.order_id)
        / SUM(COUNT(DISTINCT o.order_id))
          OVER (PARTITION BY o.order_status)
        AS DECIMAL(5,2)
    ) AS percentage_within_status
FROM selected_orders AS o
JOIN payment_by_order AS p
    ON o.order_id = p.order_id
GROUP BY
    o.order_status,
    p.payment_type
ORDER BY
    o.order_status,
    total_orders DESC;

/*Khi so sánh giữa các đơn bị canceled và các đơn delivered, thì tỉ lệ sử dụng credit_card đều cao như nhau, chứng tỏ đây chỉ là 
hành vi sử dụng thẻ của khách hàng chứ không nói lên được điều gì cả*/

SELECT
    YEAR(TRY_CONVERT(datetime, order_delivered_carrier_date)) AS carrier_year,
    MONTH(TRY_CONVERT(datetime, order_delivered_carrier_date)) AS carrier_month,
    COUNT(*) AS canceled_orders_with_carrier_date
FROM staging.olist_orders
WHERE order_status = 'canceled'
  AND NULLIF(TRIM(order_delivered_carrier_date), '') IS NOT NULL
GROUP BY
    YEAR(TRY_CONVERT(datetime, order_delivered_carrier_date)),
    MONTH(TRY_CONVERT(datetime, order_delivered_carrier_date))
ORDER BY carrier_year, carrier_month;

/*Đáng chú ý là ngày bàn giao của những đơn bị canceled đều tập trung vào tháng 10/2016 và quý I/2018, hoàn toàn không có năm 2017*/

SELECT
    order_id,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    DATEDIFF(
        DAY,
        TRY_CONVERT(datetime, order_purchase_timestamp),
        TRY_CONVERT(datetime, order_delivered_carrier_date)
    ) AS days_purchase_to_carrier
FROM staging.olist_orders
WHERE order_status = 'canceled'
  AND NULLIF(TRIM(order_delivered_carrier_date), '') IS NOT NULL
ORDER BY days_purchase_to_carrier;

/*Khoảng cách giữa ngày bàn giao và ngày đặt mua chủ yếu tập trung từ 1-6 . Có 2 đơn là trùng ngày bàn giao đơn vị vận chuyển
và ngày đặt mua. Điều này có thể hiểu là do quy trình xử lý đơn hàng nhanh của shop chẳng hạn? Chưa có dấu hiệu rõ ràng*/

SELECT
    COUNT(*) AS total_canceled_with_carrier_date,

    SUM(
        CASE
            WHEN NULLIF(
                TRIM(order_delivered_customer_date), ''
            ) IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS with_customer_delivery_date,

    SUM(
        CASE
            WHEN NULLIF(
                TRIM(order_delivered_customer_date), ''
            ) IS NULL
            THEN 1 ELSE 0
        END
    ) AS without_customer_delivery_date
FROM staging.olist_orders
WHERE order_status = 'canceled'
  AND NULLIF(
      TRIM(order_delivered_carrier_date), ''
  ) IS NOT NULL;

/*Bất thường xảy ra khi có 6 đơn hàng bị canceled nhưng lại tồn tại ngày giao đến khách hàng, sẽ phân tích khi đi qua cột order_delivered_customer_date*/

/*Trong quá trình điều tra missing ở order_delivered_carrier_date thì lại phát hiện một bất thường nữa. Như cái giả thuyết trước
đó về order_approved_at, tôi cho rằng chỉ khi họ thanh toán thì cột này mới xuất hiện. Nhưng sau khi xem qua các đơn hàng bị canceled
thì nhận thấy rằng có 75 đơn hàng bị canceled nhưng vẫn tồn tại ngày giao cho đơn vị vận chuyển. Điều này có nghĩa là
nghĩa là mâu thuẫn với ái giả thuyết trên. Phải quay lại tìm nguyên nhân missing của cột order_approved_at*/

/*Ngoài ra, đối với các đơn hàng được delivered thì mới tồn tại mã đơn đó trong order_payment*/

SELECT
    o.order_status,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN p.order_id IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS orders_with_payment,
    SUM(
        CASE
            WHEN p.order_id IS NULL THEN 1
            ELSE 0
        END
    ) AS orders_without_payment
FROM staging.olist_orders AS o
LEFT JOIN (
    SELECT DISTINCT order_id
    FROM staging.olist_order_payments
) AS p
    ON o.order_id = p.order_id
GROUP BY o.order_status
ORDER BY total_orders DESC;

/*Khẳng định trên là sai vì khi kiểm tra thì toàn bộ các đơn hàng đều có tồn tại trong order_payment, ngoại trù 1 đơn thuộc loại 
delivered*/

/*Một phát hiện ngoài lề là trong SQL kiểm tra có 2 đơn hàng delivered bị khuyết ngày giao cho đơn vị vận chuyển
trong khi kiểm tra bằng filter trong excel thì lại không có missing nào*/

/*Thực tế thì thật sự có 2 đơn bị miss trong Excel nhưng filter lại không nhận ra*/

/*Sau khi tiến hành kiểm tra 75 đơn hàng bị canceled nhưng vẫn tồn tại ngày giao
cho đơn vị vận chuyển thì có 1 điều kiện cần phải kiểm tra*/

/*Đơn hàng được giao cho đơn vị vận chuyển nhưng bị hủy thì không thể tồn tại ngày giao đến khách được 
(thật ra là vẫn tồn tại được giả sử trường hợp đó người mua trả hàng ngay lúc nhận hàng chẳng hạn?)*/

/*Phương án là giữ NULL cho cột order_delivered_carrier_date*/






/*Investigating order_delivered_customer_date*/


