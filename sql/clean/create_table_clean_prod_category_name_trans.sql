create table clean.product_category_name_translation as
select 
	trim(column1) as product_category_name,
	trim(column2) as product_category_name_english
from raw.product_category_name_translation
where column1 not in ('Column1', 'product_category_name');