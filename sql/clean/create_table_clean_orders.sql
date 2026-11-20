CREATE TABLE clean.orders AS
WITH typed AS (
    SELECT
        order_id,
        customer_id,
        LOWER(TRIM(order_status))                                      AS order_status,
        NULLIF(TRIM(order_purchase_timestamp), '')::TIMESTAMP          AS purchase_ts,
        NULLIF(TRIM(order_approved_at), '')::TIMESTAMP                 AS approved_ts,
        NULLIF(TRIM(order_delivered_carrier_date), '')::TIMESTAMP      AS carrier_ts,
        NULLIF(TRIM(order_delivered_customer_date), '')::TIMESTAMP     AS delivered_ts,
        NULLIF(TRIM(order_estimated_delivery_date), '')::TIMESTAMP     AS estimated_ts
    FROM raw.orders
)
SELECT
    *,
    (order_status = 'delivered'
        AND delivered_ts IS NOT NULL
        AND delivered_ts >= purchase_ts)  AS has_valid_delivery,
    (delivered_ts > estimated_ts)         AS is_late
FROM typed;

