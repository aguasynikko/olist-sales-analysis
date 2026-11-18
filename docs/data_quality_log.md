# Data Quality Log

| Table | Issue | Rows affected | Decision |
|---|---|---|---|
| order_reviews | Comments contain embedded line breaks and quotes; the DBeaver import produced 178,344 rows | 79,120 extra rows | Reloaded with psql `\copy`, giving the correct 99,224 |
| product_category_name_translation | Header rows loaded as data | 1 to 2 rows | Header handled in `clean` (renamed columns, filtered rows) |
| geolocation | Corrupted city names (e.g. `sÃ£o`) and about 1M rows with duplicate zip prefixes | to be counted | To be cleaned and deduplicated in `clean` |