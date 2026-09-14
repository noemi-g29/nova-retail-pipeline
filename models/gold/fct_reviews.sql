with stg_reviews as (
    select * from {{ ref('stg_reviews') }}
)

select
    review_id,
    product_id,
    review_timestamp,
    cast(review_timestamp as date) as review_date, -- Joins to dim_date.date_key
    rating,
    review_text,
    reviewer_name,
    reviewer_email,
    reviewer_country,
    reviewer_city
from stg_reviews