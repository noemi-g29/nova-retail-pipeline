with stg_targets as (
    select * from {{ ref('stg_targets') }}
)

select
    md5(concat(region, product_category, cast(target_month as string))) as target_key,
    region,
    product_category,
    cast(target_month as date) as target_month, 
    target_revenue
from stg_targets