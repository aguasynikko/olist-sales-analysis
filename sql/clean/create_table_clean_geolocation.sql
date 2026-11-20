CREATE TABLE clean.geolocation AS
WITH fixed AS (
    SELECT
        LPAD(geolocation_zip_code_prefix, 5, '0') AS zip_prefix,
        geolocation_lat::NUMERIC                  AS lat,
        geolocation_lng::NUMERIC                  AS lng,
        TRIM(LOWER(UNACCENT(
            REGEXP_REPLACE(
            REGEXP_REPLACE(
            REGEXP_REPLACE(
            REGEXP_REPLACE(
            REGEXP_REPLACE(geolocation_city, 'Ã[£¡¢]', 'a', 'g'),
                                             'Ã[©ª]',   'e', 'g'),
                                             'Ã[³´µ]',  'o', 'g'),
                                             'Ãº',       'u', 'g'),
                                             'Ã§',       'c', 'g')
        ))) AS city,
        geolocation_state AS state
    FROM raw.geolocation
)
SELECT
    zip_prefix,
    AVG(lat) AS lat,
    AVG(lng) AS lng,
    MODE() WITHIN GROUP (ORDER BY city)  AS city,
    MODE() WITHIN GROUP (ORDER BY state) AS state
FROM fixed
GROUP BY zip_prefix;