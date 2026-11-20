# Data Quality Log

Project: Olist E-Commerce Sales and Delivery Analysis
Stack: PostgreSQL, SQL (DBeaver), Power BI
Method: all 9 source CSVs were loaded as text into the `raw` schema and never edited. Every fix is applied in the `clean` schema, so the cleaning can be re-run at any time.

Items marked **TODO** need a number from your own database. Run the query shown and replace the placeholder.

## 1. Raw load

| Table | Rows loaded |
|---|---|
| geolocation | 1,000,163 |
| order_items | 112,650 |
| order_payments | 103,886 |
| order_reviews | 99,224 |
| orders | 99,441 |
| customers | 99,441 |
| products | 32,951 |
| sellers | 3,095 |
| product_category_name_translation | 72 (71 categories plus 1 header row) |

## 2. Issues found and decisions

### Load issues

| Table | Issue | Rows affected | Decision |
|---|---|---|---|
| order_reviews | Comments contain embedded line breaks and quotes. The DBeaver CSV import produced 178,344 rows instead of 99,224 | 79,120 extra rows | Emptied the table and reloaded with psql `\copy`, which gave the correct 99,224 |
| product_category_name_translation | Header row loaded as data, and the Excel view showed generic column names (Column1, Column2) | 1 to 2 rows | Loaded as `column1` and `column2`. In `clean`, filtered the header rows and renamed the columns. Final result: 71 categories |

### Lookup tables

| Table | Issue | Rows affected | Decision |
|---|---|---|---|
| geolocation | About 1M rows for about 19K distinct zip prefixes, so a join would multiply rows | 1,000,163 rows reduced to 19,015 | Collapsed to one row per zip prefix: average latitude and longitude, most common city and state |
| geolocation | Corrupted city names (e.g. `sÃ£o paulo`) and mixed accent and case variants | **TODO**: count rows where the city has characters other than lowercase letters and spaces | Repaired corrupted characters, removed accents, lowercased, trimmed. Zip prefix padded to 5 digits |
| customers | No cleaning issues found. `customer_id` unique, `customer_unique_id` has repeats because customers can order more than once | 99,441 orders, 96,096 unique customers | Standardized text only. City names with hyphens and apostrophes (e.g. `santa barbara d'oeste`) are real names and were kept |
| sellers | Malformed city values: suffixes after a slash, comma, backslash or hyphen (e.g. `maua/sao paulo`, `lages - sc`), brackets, a postal code and an email address in the city field | 26 rows, 24 distinct values | Removed suffixes with anchored patterns. For the postal code and email, took the city from geolocation by zip prefix (`unknown` if no match) |
| sellers | Typos and abbreviations (e.g. `sao pauo`, `garulhos`, `floranopolis`, `sbc`, `sp`) | 24 values mapped | Fixed with an exact-match mapping table. Real cities that only look like typos (Tupã, Ubá) were left alone |
| sellers | Real names containing apostrophes (e.g. `santa barbara d'oeste`) | 5 rows | Kept as they are |
| products | Null product category | **TODO**: `SELECT COUNT(*) FROM raw.products WHERE product_category_name IS NULL OR product_category_name = ''` | Replaced with `Unknown` |
| products | Null name length, description length and photo count | **TODO**: count nulls in the three columns | Set to 0. This lowers the averages of those columns, so exclude zeros when averaging |
| products | Misspelled column names `product_name_lenght` and `product_description_lenght` | 2 columns | Renamed to `length` |
| products | Product `09ff539a...` missing weight and dimensions | 1 row | Filled with the median of each column |
| products | Product `5eb56465...` had an ID but no other values. It was first dropped, then the integrity check found 17 order items that reference it | 1 product, 17 order items | Restored as category `Unknown`, text lengths 0, median dimensions, so no sales are orphaned |
| products | Categories with no English translation | **TODO**: list them with `SELECT DISTINCT product_category_name FROM clean.products WHERE product_category_name_english = 'Unknown'` | Set the English name to `Unknown` |

### Transaction tables

| Table | Issue | Rows affected | Decision |
|---|---|---|---|
| orders | Missing delivery dates, almost all legitimate (invoiced, processing, unavailable, canceled and created orders have not shipped) | 2,965 without a delivered date, 1,783 without a carrier date, 160 without an approval date | Kept as NULL |
| orders | Status `delivered` but no delivered date | 8 | Kept. `has_valid_delivery` flag is false |
| orders | Delivered date present but status is not `delivered` | 6 | Kept. `has_valid_delivery` flag is false |
| orders | Status `delivered` but no approval timestamp | 14 | Kept and noted |
| orders | Carrier pickup before purchase | 166 | Kept and noted |
| orders | Carrier pickup before approval | 1,359 | Kept and noted |
| orders | Delivered to customer before carrier pickup | 23 | Kept and noted |
| orders | Dates were already in YYYY-MM-DD HH:MM:SS format | 0 bad formats | Cast all five date columns to `TIMESTAMP`. Added `has_valid_delivery` and `is_late` flags. 7,827 delivered orders (about 8.1%) arrived after the estimated date |
| order_items | `shipping_limit_date` in 2020 for orders placed in 2017 (impossible) | 4 | Set to NULL, rows kept |
| order_items | Price and freight already had exactly 2 decimals, so no rounding needed | 0 | Converted to `NUMERIC(10,2)` |
| order_items | Freight value of 0 (free shipping) | 383 | Kept, it is legitimate |
| order_items | Orders with no items | 775 orders (603 unavailable, 164 canceled, 5 created, 2 invoiced, 1 shipped) | Kept in orders, they simply have no items |
| order_payments | Credit card payments with 0 installments | 2 | Set to 1 installment |
| order_payments | Payment type `not_defined` with value 0.00, all on canceled orders | 3 | Kept |
| order_payments | Vouchers with a value of 0 | 6 | Kept, those orders have other payments |
| order_payments | Gaps in `payment_sequential` | 80 orders | Kept and noted |
| order_payments | Delivered order with no payment row | 1 (`bfbd0f9b...`) | Kept and noted |
| order_payments | Payments differ from item price plus freight by more than R$0.01 | 303 of 98,666 orders | Expected (installment interest, vouchers, orders with no items). **Revenue is defined from `order_items.price`, not from payments** |
| order_reviews | `review_id` repeats across different orders | 789 ids, 814 extra rows | Kept all rows. Primary key is `(review_id, order_id)` |
| order_reviews | Orders with more than one review (up to 3) | 547 orders | Added `is_latest_review` flag. KPIs use the latest review per order |
| order_reviews | No comment title | 87,658 | `No Review` |
| order_reviews | No comment message | 58,274 | `No Review`, plus a `has_comment` flag (40,950 true) |
| order_reviews | Line breaks inside messages | 3,834 | Replaced with a space |
| order_reviews | Leading or trailing spaces in messages | 9,424 | Trimmed |
| order_reviews | Corrupted text (`Ã`) in comments | 451 reviews | Not fixed. Free text is not used in the KPIs. Flagged with `has_encoding_issue` |
| order_reviews | `review_creation_date` holds a date only (time is 00:00:00) | 99,139 of 99,224 | Cast to `TIMESTAMP`. No separate time column, since it would add nothing |
| order_reviews | Review created before the order's purchase date | 64 | Kept and noted |

## 3. Integrity checks (clean schema)

| Check | Result |
|---|---|
| Orders without a customer | 0 |
| Order items without an order | 0 |
| Order items without a product | 0 (after restoring product `5eb56465...`) |
| Order items without a seller | 0 |
| Payments without an order | 0 |
| Reviews without an order | 0 |
| Customers whose zip prefix is missing from geolocation | 278 (0.28%) |
| Sellers whose zip prefix is missing from geolocation | 7 (0.23%) |

The missing zip prefixes are a gap in the source geolocation file. Those rows are kept and joined with a LEFT JOIN, so they stay in the sales numbers and only lack map coordinates.

## 4. Keys added in the clean schema

- Primary keys: `customers(customer_id)`, `sellers(seller_id)`, `geolocation(zip_prefix)`, `products(product_id)`, `orders(order_id)`, `order_items(order_id, order_item_id)`, `order_payments(order_id, payment_sequential)`, `order_reviews(review_id, order_id)`
- Foreign keys: `orders` to `customers`; `order_items` to `orders`, `products` and `sellers`; `order_payments` to `orders`; `order_reviews` to `orders`

## 5. Reference totals (use these to validate the dashboard)

| Measure | Value |
|---|---|
| Orders | 99,441 |
| Order items | 112,650 |
| Total item price | R$13,591,643.70 |
| Total freight | R$2,251,909.54 |
| Total payments | R$16,008,872.12 |
| Delivered orders arriving late | 7,827 (about 8.1%) |
