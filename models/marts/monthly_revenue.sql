with base as (
    select * from {{ ref('int_sales_unified') }}
    where is_cancellation = false
),

monthly as (
    select
        to_char(date_trunc('month', invoice_date), 'YYYY-MM') as revenue_month,
        count(distinct invoice_no)               as total_orders,
        sum(quantity)                            as total_units_sold,
        round(sum(revenue), 2)                   as total_revenue,
        round(avg(revenue), 2)                   as avg_order_value,
        count(distinct customer_id)              as unique_customers
    from base
    group by 1
)

select * from monthly
order by revenue_month