CREATE TABLE clean.order_reviews AS
WITH typed AS (
    SELECT
        review_id,
        order_id,
        TRIM(review_score)::SMALLINT AS review_score,
        NULLIF(TRIM(REGEXP_REPLACE(review_comment_title,   '[\r\n]+', ' ', 'g')), '') AS title,
        NULLIF(TRIM(REGEXP_REPLACE(review_comment_message, '[\r\n]+', ' ', 'g')), '') AS message,
        TRIM(review_creation_date)::TIMESTAMP   AS creation_ts,
        TRIM(review_answer_timestamp)::TIMESTAMP AS answer_ts
    FROM raw.order_reviews
)
SELECT
    review_id,
    order_id,
    review_score,
    COALESCE(title,   'No Review') AS review_comment_title,
    COALESCE(message, 'No Review') AS review_comment_message,
    (message IS NOT NULL)          AS has_comment,
    (COALESCE(message, '') LIKE '%Ã%' OR COALESCE(title, '') LIKE '%Ã%') AS has_encoding_issue,
    creation_ts,
    answer_ts,
    ROW_NUMBER() OVER (PARTITION BY order_id
                       ORDER BY creation_ts DESC, answer_ts DESC, review_id DESC) = 1 AS is_latest_review
FROM typed;