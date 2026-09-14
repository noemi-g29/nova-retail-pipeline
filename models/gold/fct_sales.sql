with stg_sales as (
    select * from {{ ref('stg_sales') }}
)

select
    order_id,
    cast(transaction_date as date) as date_key, 
    md5(customer_email) as customer_id,
    product_id,
    transaction_status,
    quantity,
    unit_price,
    discount_pct,
    gross_amount,
    gross_profit
from stg_sales