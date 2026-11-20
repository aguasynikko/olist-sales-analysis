CREATE TABLE star.dim_date AS
SELECT
    d::DATE                          AS date_key,
    EXTRACT(YEAR FROM d)::INT        AS year,
    EXTRACT(QUARTER FROM d)::INT     AS quarter,
    EXTRACT(MONTH FROM d)::INT       AS month_num,
    TO_CHAR(d, 'Mon')                AS month_name,
    TO_CHAR(d, 'YYYY-MM')            AS year_month,
    EXTRACT(ISODOW FROM d)::INT      AS weekday_num,
    TO_CHAR(d, 'Dy')                 AS weekday_name,
    EXTRACT(ISODOW FROM d) >= 6      AS is_weekend
FROM generate_series('2016-09-01'::DATE, '2018-12-31'::DATE, '1 day') AS d;