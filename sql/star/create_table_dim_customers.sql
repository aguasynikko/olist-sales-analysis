CREATE TABLE star.dim_customers AS
SELECT
    c.customer_id,
    c.customer_unique_id,
    c.zip_prefix,
    c.city,
    c.state,
    g.lat,
    g.lng
FROM clean.customers AS c
LEFT JOIN clean.geolocation AS g
    ON c.zip_prefix = g.zip_prefix;