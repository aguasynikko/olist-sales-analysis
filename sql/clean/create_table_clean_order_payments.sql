CREATE TABLE clean.order_payments AS
SELECT
    order_id,
    TRIM(payment_sequential)::INT                         AS payment_sequential,
    LOWER(TRIM(payment_type))                             AS payment_type,
    CASE
        WHEN TRIM(payment_installments)::INT = 0
         AND LOWER(TRIM(payment_type)) = 'credit_card' THEN 1
        ELSE TRIM(payment_installments)::INT
    END                                                   AS payment_installments,
    TRIM(payment_value)::NUMERIC(10,2)                    AS payment_value
FROM raw.order_payments;