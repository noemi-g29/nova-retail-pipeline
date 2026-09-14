with date_bounds as (
    -- Cast existing transaction_date to DATE to ensure clean min/max boundaries
    select 
        min(to_date(transaction_date)) as start_date,
        max(to_date(transaction_date)) as end_date
    from {{ ref('stg_sales') }}
),

year_boundaries as (
    select 
        to_date(date_trunc('year', start_date)) as min_date,
        to_date(add_months(date_trunc('year', end_date), 12) - interval 1 day) as max_date
    from date_bounds
),

date_spine as (
    select explode(
        sequence(
            (select min_date from year_boundaries), 
            (select max_date from year_boundaries), 
            interval 1 day
        )
    ) as date_day
),

calculated as (
    select
        -- Force pure DATE type (strips timestamp 'T00:00:00')
        to_date(date_day) as date_key,
        year(date_day) as year,
        quarter(date_day) as quarter,
        month(date_day) as month_number,
        date_format(date_day, 'MMMM') as month_name,
        date_format(date_day, 'MMM') as month_name_short,
        
        -- Force pure DATE type for first day of month
        to_date(date_trunc('month', date_day)) as first_day_of_month,
        
        date_format(date_day, 'yyyy-MM') as year_month,
        date_format(date_day, 'MMM-yy') as target_month_format,
        dayofweek(date_day) as day_of_week,
        date_format(date_day, 'EEEE') as day_name,
        case when dayofweek(date_day) in (1, 7) then true else false end as is_weekend
    from date_spine
)

select * from calculated