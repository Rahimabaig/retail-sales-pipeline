with base as (
    select * from {{ ref('int_sales_unified') }}
    where is_cancellation = false
),

product_performance as (
    select
        stock_code,
        product_description,
        count(distinct invoice_no)               as total_orders,
        sum(quantity)                            as total_units_sold,
        round(sum(revenue), 2)                   as total_revenue,
        round(avg(unit_price), 2)                as avg_unit_price,
        count(distinct customer_id)              as unique_customers,
        case
            when sum(quantity) < 50  then 'Dead Stock'
            when sum(quantity) < 200 then 'Slow Moving'
            when sum(quantity) < 500 then 'Moderate'
            else 'Fast Moving'
        end                                      as stock_velocity
    from base
    group by stock_code, product_description
)

select * from product_performance
order by total_revenue desc