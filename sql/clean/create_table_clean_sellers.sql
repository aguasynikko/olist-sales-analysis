CREATE TABLE clean.sellers AS
WITH step1 AS (
    SELECT
        seller_id,
        LPAD(seller_zip_code_prefix, 5, '0') AS zip_prefix,
        TRIM(LOWER(UNACCENT(seller_city)))   AS city,
        UPPER(TRIM(seller_state))            AS state
    FROM raw.sellers
),
step2 AS (
    SELECT
        seller_id, zip_prefix, state,
        TRIM(
            REGEXP_REPLACE(
            REGEXP_REPLACE(
            REGEXP_REPLACE(
            REGEXP_REPLACE(city, '\s*(/|\\|,).*$',   ''),
                                 '\s*-\s*[a-z]{2}$', ''),
                                 '\s*\(.*\)$',       ''),
                                 '\s+',              ' ', 'g')
        ) AS city
    FROM step1
),
fixes (bad, good) AS (
    VALUES
    ('sao pauo','sao paulo'), ('sao paluo','sao paulo'), ('sao paulop','sao paulo'),
    ('sao paulo sp','sao paulo'), ('sp','sao paulo'),
    ('sbc','sao bernardo do campo'), ('sao bernardo do capo','sao bernardo do campo'),
    ('ao bernardo do campo','sao bernardo do campo'),
    ('s jose do rio preto','sao jose do rio preto'), ('sao jose do rio pret','sao jose do rio preto'),
    ('scao jose do rio pardo','sao jose do rio pardo'),
    ('sao jose dos pinhas','sao jose dos pinhais'),
    ('balenario camboriu','balneario camboriu'), ('cascavael','cascavel'),
    ('floranopolis','florianopolis'), ('mogi das cruses','mogi das cruzes'),
    ('portoferreira','porto ferreira'), ('belo horizont','belo horizonte'),
    ('sando andre','santo andre'), ('garulhos','guarulhos'),
    ('ribeirao pretp','ribeirao preto'), ('robeirao preto','ribeirao preto'),
    ('riberao preto','ribeirao preto'), ('tabao da serra','taboao da serra')
)
SELECT
    s.seller_id,
    s.zip_prefix,
    CASE
        WHEN s.city ~ '^[0-9]+$' OR s.city LIKE '%@%' OR s.city = ''
            THEN COALESCE(g.city, 'unknown')
        ELSE COALESCE(f.good, s.city)
    END AS city,
    s.state
FROM step2 s
LEFT JOIN fixes f ON f.bad = s.city
LEFT JOIN clean.geolocation g ON g.zip_prefix = s.zip_prefix;