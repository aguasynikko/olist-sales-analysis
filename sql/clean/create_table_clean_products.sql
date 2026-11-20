CREATE TABLE clean.products AS
WITH base AS (
    SELECT
        product_id,
        COALESCE(NULLIF(TRIM(product_category_name), ''), 'Unknown')   AS product_category_name,
        COALESCE(NULLIF(TRIM(product_name_lenght), '')::INT, 0)        AS product_name_length,
        COALESCE(NULLIF(TRIM(product_description_lenght), '')::INT, 0) AS product_description_length,
        COALESCE(NULLIF(TRIM(product_photos_qty), '')::INT, 0)         AS product_photos_qty,
        NULLIF(TRIM(product_weight_g), '')::NUMERIC                    AS product_weight_g,
        NULLIF(TRIM(product_length_cm), '')::NUMERIC                   AS product_length_cm,
        NULLIF(TRIM(product_height_cm), '')::NUMERIC                   AS product_height_cm,
        NULLIF(TRIM(product_width_cm), '')::NUMERIC                    AS product_width_cm
    FROM raw.products
    WHERE product_id <> '5eb564652db742ff8f28759cd8d2652a'
),
medians AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY product_weight_g) AS med_weight,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY product_length_cm) AS med_length,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY product_height_cm) AS med_height,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY product_width_cm)  AS med_width
    FROM base
)
SELECT
    b.product_id,
    b.product_category_name,
    COALESCE(t.product_category_name_english, 'Unknown') AS product_category_name_english,
    b.product_name_length,
    b.product_description_length,
    b.product_photos_qty,
    COALESCE(b.product_weight_g,  m.med_weight) AS product_weight_g,
    COALESCE(b.product_length_cm, m.med_length) AS product_length_cm,
    COALESCE(b.product_height_cm, m.med_height) AS product_height_cm,
    COALESCE(b.product_width_cm,  m.med_width)  AS product_width_cm
FROM base b
CROSS JOIN medians m
LEFT JOIN clean.product_category_name_translation t
       ON t.product_category_name = b.product_category_name;