with unique_customers as (
    select distinct
        customer_email,
        customer_name,
        customer_phone
    from {{ ref('stg_sales') }}
    where customer_email is not null
)

select
    md5(customer_email) as customer_id,
    customer_name,
    customer_email,
    customer_phone
from unique_customers