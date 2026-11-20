CREATE TABLE star.dim_sellers AS
SELECT
    s.seller_id,
    s.zip_prefix,
    s.city,
    s.state,
    g.lat,
    g.lng
FROM clean.sellers AS s
LEFT JOIN clean.geolocation AS g
    ON s.zip_prefix = g.zip_prefix;