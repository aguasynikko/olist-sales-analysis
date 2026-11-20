CREATE TABLE star.fact_order_items AS
SELECT
    oi.order_id,
    oi.order_item_id,
    o.customer_id,
    oi.product_id,
    oi.seller_id,
    o.purchase_ts::DATE AS purchase_date,
    o.order_status,
    oi.price,
    oi.freight_value,
    CASE WHEN o.has_valid_delivery
         THEN ROUND(EXTRACT(EPOCH FROM (o.delivered_ts - o.purchase_ts)) / 86400, 1)
    END AS delivery_days,
    o.is_late,
    r.review_score
FROM clean.order_items AS oi
JOIN clean.orders AS o
    ON oi.order_id = o.order_id
LEFT JOIN clean.order_reviews AS r
    ON oi.order_id = r.order_id
   AND r.is_latest_review;