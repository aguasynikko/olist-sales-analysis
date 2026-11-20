CREATE TABLE clean.order_items AS
SELECT
    order_id,
    TRIM(order_item_id)::INT                    AS order_item_id,
    product_id,
    seller_id,
    CASE
        WHEN NULLIF(TRIM(shipping_limit_date), '')::TIMESTAMP > TIMESTAMP '2019-01-01' THEN NULL
        ELSE NULLIF(TRIM(shipping_limit_date), '')::TIMESTAMP
    END                                         AS shipping_limit_ts,
    TRIM(price)::NUMERIC(10,2)                  AS price,
    TRIM(freight_value)::NUMERIC(10,2)          AS freight_value
FROM raw.order_items;