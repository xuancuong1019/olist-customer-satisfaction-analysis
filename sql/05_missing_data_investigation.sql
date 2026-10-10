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

/*Trong tổng số các đơn hàng đã được delivered và sử dụng phương thức thanh toán là boleto, 
thì chỉ có 14 đơn missing order_approved_at chiếm tỉ lệ 0,073%*. Điều đó cho thấy 
vấn đề thiếu order_approved_at không xảy ra phổ biến trong toàn bộ nhóm đơn boleto. 
Tuy nhiên, chúng ta vẫn chưa biết tỷ lệ này có cao bất thường so với những phương thức thanh toán khác 
hay không./ */
 

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

/*Sau khi kiểm tra các đơn hàng với từng loại thanh toán khác nhau, thì duy nhất chỉ có boleto xảy ra 
trường hợp missing và đúng 14 đơn hàng. Hiện tại chưa thể kết luận được, có hai hướng cần kiểm tra thêm là 
về thời gian mua hàng và quy trình thanh toán*/

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

/*Hiện tại, dữ liệu ủng hộ nhận định rằng các trường hợp missing có xu hướng tập trung vào một số ngày đặt hàng nhất định. 
Nhưng chưa đủ bằng chứng để kết luận nguyên nhân là boleto hay lỗi hệ thống trong những ngày đó.Có một câu hỏi quan trọng: 
nếu ngày 18/02 có một vấn đề chung trong hệ thống, tại sao các đơn thanh toán bằng thẻ vẫn có order_approved_at đầy đủ? 
Điều này khiến giả thuyết về quy trình thanh toán boleto trở nên đáng kiểm tra, nhưng chưa chứng minh được nó.*/


WITH order_payment AS (
    SELECT DISTINCT
        order_id,
        payment_type
    FROM staging.olist_order_payments
),
daily_payment_stats AS (
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
    INNER JOIN order_payment AS p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
      AND CAST(o.order_purchase_timestamp AS DATE)
          BETWEEN '2017-02-17' AND '2017-02-19'
    GROUP BY
        CAST(o.order_purchase_timestamp AS DATE),
        p.payment_type
)
SELECT
    purchase_date,
    payment_type,
    total_orders,
    missing_orders,
    CAST(
        100.0 * missing_orders
        / NULLIF(total_orders, 0)
        AS DECIMAL(10, 2)
    ) AS missing_rate_pct
FROM daily_payment_stats
ORDER BY
    purchase_date,
    payment_type;


/*Trong khoảng thời gian đang kiểm tra chỉ duy nhất các đơn hàng thanh toán bằng boleto xảy ra missing
Kiểm tra giả thuyết cuối cùng vấn đề có thể liên quan đến cách hệ thống ghi nhận hoặc xử lý thông tin phê duyệt đối với một nhóm đơn boleto, 
thay vì một lỗi missing phân bố ngẫu nhiên.*/

SELECT
    order_id,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_status
FROM staging.olist_orders
WHERE order_status = 'delivered'
  AND (
      order_approved_at IS NULL
      OR TRIM(order_approved_at) = ''
  )
ORDER BY order_purchase_timestamp;


/*Sau khi tìm hiểu và đánh giá, tôi quyết định dừng việc điều tra missing values ở cột này 
vì chưa đủ bằng chứng dẫn đến nguyên nhân và thiếu tri thức về quy trình nghiệp vụ. Đồng thời con số 160/99441 dòng 
là quá nhỏ để thực sự ảnh hưởng đến kết luận và phân tích kinh doanh. Đây là giới hạn của dữ liệu công khai*/

/*Phương án hiện tại là chuẩn hóa NULL cho các giá trị khuyết ở cột order_approved_at*/

/*Đối với 14 đơn bất thường thì sẽ lưu vào bảng log, không sửa dữ liệu gốc*/


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

/*Shipped ghi nhận 0 trường hợp missing ngày giao đến đơn vị vận chuyển, điều mà hợp lý. Tuy nhiên ở delivered
lại xuất hiện 2 trường hợp bị miss cột này, nên cần kiểm tra lại*/


SELECT
    *,
    LEN(order_delivered_carrier_date) AS value_length
FROM staging.olist_orders
WHERE order_status = 'delivered'
  AND (
      order_delivered_carrier_date IS NULL
      OR TRIM(order_delivered_carrier_date) = ''
  );

/*Một phát hiện ngoài lề là trong SQL kiểm tra có 2 đơn hàng delivered bị khuyết ngày giao cho đơn vị vận chuyển
trong khi kiểm tra bằng filter trong excel thì lại không có missing nào*/

/*Thực tế thì thật sự có 2 đơn bị miss trong Excel nhưng filter lại không nhận ra*/

/*Sau khi tiến hành kiểm tra 75 đơn hàng bị canceled nhưng vẫn tồn tại ngày giao
cho đơn vị vận chuyển thì có 1 điều kiện cần phải kiểm tra*/

/*Trường hợp thứ 1: Đơn hàng được giao cho đơn vị vận chuyển nhưng bị hủy thì không thể tồn tại ngày giao đến khách được 
(thật ra là vẫn tồn tại được giả sử trường hợp đó người mua trả hàng ngay lúc nhận hàng chẳng hạn?)*/

/*Vậy nên sẽ tiến hành kiểm tra các đơn bị hủy và tồn tại 2 cột order_delivered_carrier_date và order_delivered_customer_date*/
