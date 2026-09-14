with source as (
    select * from {{ source('bronze', 'bronze_sales') }}
),

cleaned as (
    select
        cast(order_id as string) as order_id,
        
        coalesce(
            case when lower(trim(transaction_date)) = 'today' then current_date() end,
            try_to_date(transaction_date, 'yyyy-MM-dd'),
            try_to_date(transaction_date, 'yyyy/MM/dd'),
            try_to_date(transaction_date, 'dd-MMM-yyyy'),
            try_to_date(transaction_date, 'MM/dd/yyyy'),
            try_to_date(transaction_date, 'dd/MM/yyyy'),
            date(_ingested_at)
        ) as transaction_date,
        
        trim(split(customer_info, '\\|')[0]) as customer_name,
        trim(lower(split(customer_info, '\\|')[1])) as customer_email,
        trim(split(customer_info, '\\|')[2]) as customer_phone,
        
        cast(product_id as string) as product_id,
        trim(product_category) as product_category,
        
        try_cast(regexp_replace(price, '[\\$,€,£,]', '') as double) as unit_price,
        
        case 
            when cast(qty as int) < 0 then 'Returned/Cancelled'
            else 'Completed'
        end as transaction_status,
        
        abs(cast(qty as int)) as quantity,
        
        case 
            when lower(trim(discount_pct)) = 'n/a' or discount_pct is null or trim(discount_pct) = '' then 0.0
            when discount_pct like '%\%' then try_cast(replace(discount_pct, '%', '') as double) / 100.0
            else coalesce(try_cast(discount_pct as double), 0.0)
        end as discount_pct,
        
        _ingested_at
    from source
    where order_id is not null
)

select 
    *,
    (quantity * unit_price * (1 - discount_pct)) as gross_amount,
    (quantity * unit_price * (1 - discount_pct) * 0.30) as gross_profit
from cleaned