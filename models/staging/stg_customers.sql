with source as (
    select * from {{ source('raw_data', 'raw_customers') }}
),

cleaned as (
    select
        split_part(customerid, '.', 1)  as customer_id,
        trim(country)                   as country
    from source
    where customerid is not null
        and trim(customerid) != ''
),

deduplicated as (
    select
        customer_id,
        max(country) as country
    from cleaned
    group by customer_id
)

select * from deduplicated

