with source as (
    select * from {{ source('bronze', 'bronze_reviews') }}
),

cleaned as (
    select
        cast(review_id as string) as review_id,
        cast(product_ref as string) as product_id,
        
        -- Convert epoch timestamp (handles both milliseconds and seconds gracefully)
        case 
            when length(cast(timestamp as string)) >= 13 
                then to_timestamp(cast(timestamp as double) / 1000.0)
            else to_timestamp(cast(timestamp as double))
        end as review_timestamp,
        
        try_cast(rating as int) as rating,
        
        trim(review_text) as review_text,
        trim(user_name) as reviewer_name,
        trim(lower(user_email)) as reviewer_email,
        trim(user_country) as reviewer_country,
        trim(user_city) as reviewer_city,
        
        _ingested_at
    from source
    where review_id is not null 
      and lower(trim(cast(review_id as string))) != 'null'
      -- Clean rating bounds: must be non-null and strictly between 1 and 5 stars
      and try_cast(rating as int) is not null
      and try_cast(rating as int) >= 1
      and try_cast(rating as int) <= 5
)

select * from cleaned