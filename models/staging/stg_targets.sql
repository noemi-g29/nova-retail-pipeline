{% if execute %}
  {% set columns = adapter.get_columns_in_relation(source('bronze', 'bronze_targets')) %}
  {% set month_cols = [] %}
  {% set select_exprs = [] %}
  
  {% for col in columns %}
    {% if col.name not in ['Region', 'Category', '_ingested_at', '_source_file'] %}
      {% do month_cols.append("`" ~ col.name ~ "`") %}
      {% do select_exprs.append("cast(`" ~ col.name ~ "` as string) as `" ~ col.name ~ "`") %}
    {% endif %}
  {% endfor %}

  {% set month_cols_str = month_cols | join(', ') %}
  {% set select_exprs_str = select_exprs | join(', ') %}
{% else %}
  {% set month_cols = [] %}
{% endif %}

{% if execute and month_cols | length > 0 %}

with source as (
    select 
        Region,
        Category,
        {{ select_exprs_str }}
    from {{ source('bronze', 'bronze_targets') }}
),

unpivoted as (
    select *
    from source
    unpivot (
        target_amount for month_year in (
            {{ month_cols_str }}
        )
    )
)

select
    trim(Region) as region,
    trim(Category) as product_category,
    to_date(month_year, 'MMM-yy') as target_month,
    cast(regexp_replace(target_amount, '[\$,€,£,]', '') as double) as target_amount
from unpivoted
where target_amount is not null

{% else %}

-- Dummy query for dbt parsing/compilation phase
select
    cast(null as string) as region,
    cast(null as string) as product_category,
    cast(null as date) as target_month,
    cast(null as double) as target_amount
where 1=0

{% endif %}