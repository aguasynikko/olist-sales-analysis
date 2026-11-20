CREATE TABLE star.dim_products AS
SELECT
    product_id,
    product_category_name         AS category_pt,
    product_category_name_english AS category,
    product_photos_qty            AS photos_qty,
    product_weight_g              AS weight_g,
    product_length_cm * product_height_cm * product_width_cm AS volume_cm3
FROM clean.products;