with products_from_sales as (
    select distinct 
        cast(product_id as string) as product_id,
        trim(product_category) as product_category
    from {{ ref('stg_sales') }}
    where product_id is not null
)

select 
    product_id,
    product_category
from products_from_sales