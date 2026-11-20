SELECT 'orders without customer' AS check_name, COUNT(*) AS n
FROM clean.orders o LEFT JOIN clean.customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'items without order', COUNT(*)
FROM clean.order_items i LEFT JOIN clean.orders o ON o.order_id = i.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'items without product', COUNT(*)
FROM clean.order_items i LEFT JOIN clean.products p ON p.product_id = i.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'items without seller', COUNT(*)
FROM clean.order_items i LEFT JOIN clean.sellers s ON s.seller_id = i.seller_id
WHERE s.seller_id IS NULL
UNION ALL
SELECT 'payments without order', COUNT(*)
FROM clean.order_payments p LEFT JOIN clean.orders o ON o.order_id = p.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'reviews without order', COUNT(*)
FROM clean.order_reviews r LEFT JOIN clean.orders o ON o.order_id = r.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'customers without geolocation', COUNT(*)
FROM clean.customers c LEFT JOIN clean.geolocation g ON g.zip_prefix = c.zip_prefix
WHERE g.zip_prefix IS NULL
UNION ALL
SELECT 'sellers without geolocation', COUNT(*)
FROM clean.sellers s LEFT JOIN clean.geolocation g ON g.zip_prefix = s.zip_prefix
WHERE g.zip_prefix IS NULL;