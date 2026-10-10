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
/* 1. Missing values by order status */

SELECT
    order_status,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN NULLIF(TRIM(order_delivered_carrier_date), '') IS NULL
            THEN 1 ELSE 0
        END
    ) AS missing_orders,
    CAST(
        100.0 * SUM(
            CASE
                WHEN NULLIF(TRIM(order_delivered_carrier_date), '') IS NULL
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0)
        AS DECIMAL(6, 2)
    ) AS missing_rate_pct
FROM staging.olist_orders
GROUP BY order_status
ORDER BY missing_rate_pct DESC;


/* 2. Compare credit card usage between canceled and delivered
      orders that have a carrier date */

WITH payment_flags AS (
    SELECT
        order_id,
        MAX(CASE WHEN payment_type = 'credit_card' THEN 1 ELSE 0 END)
            AS uses_credit_card
    FROM staging.olist_order_payments
    GROUP BY order_id
)
SELECT
    o.order_status,
    COUNT(*) AS total_orders,
    SUM(COALESCE(p.uses_credit_card, 0)) AS credit_card_orders,
    CAST(
        100.0 * SUM(COALESCE(p.uses_credit_card, 0))
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(6, 2)
    ) AS credit_card_rate_pct
FROM staging.olist_orders AS o
LEFT JOIN payment_flags AS p
    ON o.order_id = p.order_id
WHERE o.order_status IN ('canceled', 'delivered')
  AND NULLIF(TRIM(o.order_delivered_carrier_date), '') IS NOT NULL
GROUP BY o.order_status;


/* 3. Monthly distribution of canceled orders with a carrier date */

WITH canceled_orders AS (
    SELECT
        TRY_CONVERT(
            datetime2,
            NULLIF(TRIM(order_delivered_carrier_date), '')
        ) AS carrier_datetime
    FROM staging.olist_orders
    WHERE order_status = 'canceled'
      AND NULLIF(TRIM(order_delivered_carrier_date), '') IS NOT NULL
)
SELECT
    COALESCE(
        CONVERT(char(7), carrier_datetime, 120),
        'Invalid datetime'
    ) AS carrier_month,
    COUNT(*) AS total_orders
FROM canceled_orders
GROUP BY
    COALESCE(
        CONVERT(char(7), carrier_datetime, 120),
        'Invalid datetime'
    )
ORDER BY carrier_month;


/* 4. Check customer delivery dates among canceled orders
      that have a carrier date */

SELECT
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN NULLIF(TRIM(order_delivered_customer_date), '') IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS with_customer_delivery_date,
    SUM(
        CASE
            WHEN NULLIF(TRIM(order_delivered_customer_date), '') IS NULL
            THEN 1 ELSE 0
        END
    ) AS without_customer_delivery_date
FROM staging.olist_orders
WHERE order_status = 'canceled'
  AND NULLIF(TRIM(order_delivered_carrier_date), '') IS NOT NULL;


/* 5. Inspect anomalous orders and their timeline */

SELECT
    order_id,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    DATEDIFF(
        DAY,
        TRY_CONVERT(datetime2,
            NULLIF(TRIM(order_purchase_timestamp), '')),
        TRY_CONVERT(datetime2,
            NULLIF(TRIM(order_delivered_carrier_date), ''))
    ) AS days_purchase_to_carrier
FROM staging.olist_orders
WHERE order_status = 'canceled'
  AND NULLIF(TRIM(order_delivered_carrier_date), '') IS NOT NULL
ORDER BY days_purchase_to_carrier, order_id;



/*Investigating order_delivered_customer_date*/
/* 1. Missing values in order_delivered_customer_date by order status */

SELECT
    order_status,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN NULLIF(TRIM(order_delivered_customer_date), '') IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_orders,
    CAST(
        100.0 * SUM(
            CASE
                WHEN NULLIF(TRIM(order_delivered_customer_date), '') IS NULL
                THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0)
        AS DECIMAL(6, 2)
    ) AS missing_rate_pct
FROM staging.olist_orders
GROUP BY order_status
ORDER BY missing_orders DESC;

/* 2. Payment method distribution for shipped orders */

SELECT
    p.payment_type,
    COUNT(DISTINCT o.order_id) AS total_orders,
    CAST(
        100.0 * COUNT(DISTINCT o.order_id)
        / NULLIF(
            (
                SELECT COUNT(DISTINCT order_id)
                FROM staging.olist_orders
                WHERE order_status = 'shipped'
            ),
            0
        )
        AS DECIMAL(6, 2)
    ) AS percentage
FROM staging.olist_orders AS o
JOIN staging.olist_order_payments AS p
    ON o.order_id = p.order_id
WHERE o.order_status = 'shipped'
GROUP BY p.payment_type
ORDER BY total_orders DESC;

/* 3. Inspect all timestamps of shipped orders */

SELECT
    order_id,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM staging.olist_orders
WHERE order_status = 'shipped'
ORDER BY order_purchase_timestamp;

/* 4. Investigating canceled orders with customer delivery dates */

SELECT
    order_id,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    DATEDIFF(
        DAY,
        TRY_CONVERT(datetime2, NULLIF(TRIM(order_purchase_timestamp), '')),
        TRY_CONVERT(datetime2, NULLIF(TRIM(order_delivered_carrier_date), ''))
    ) AS days_purchase_to_carrier,

    DATEDIFF(
        DAY,
        TRY_CONVERT(datetime2, NULLIF(TRIM(order_delivered_carrier_date), '')),
        TRY_CONVERT(datetime2, NULLIF(TRIM(order_delivered_customer_date), ''))
    ) AS days_carrier_to_customer,

    DATEDIFF(
        DAY,
        TRY_CONVERT(datetime2, NULLIF(TRIM(order_purchase_timestamp), '')),
        TRY_CONVERT(datetime2, NULLIF(TRIM(order_delivered_customer_date), ''))
    ) AS days_purchase_to_customer

FROM staging.olist_orders
WHERE order_status = 'canceled'
  AND NULLIF(TRIM(order_delivered_customer_date), '') IS NOT NULL
ORDER BY order_purchase_timestamp;