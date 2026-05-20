with cancellations as (
    select * from {{ ref('int_sales_unified') }}
    where is_cancellation = true
),

sales as (
    select * from {{ ref('int_sales_unified') }}
    where is_cancellation = false
),

monthly_cancellations as (
    select
        to_char(date_trunc('month', invoice_date), 'YYYY-MM') as revenue_month,
        count(distinct invoice_no)          as total_cancellations,
        sum(quantity)                       as total_units_cancelled,
        round(sum(revenue), 2)              as total_revenue_lost
    from cancellations
    group by 1
),

monthly_sales as (
    select
        to_char(date_trunc('month', invoice_date), 'YYYY-MM') as revenue_month,
        round(sum(revenue), 2)              as gross_revenue
    from sales
    group by 1
)

select
    c.revenue_month,
    c.total_cancellations,
    c.total_units_cancelled,
    c.total_revenue_lost,
    s.gross_revenue,
    round(c.total_revenue_lost / nullif(s.gross_revenue, 0) * 100, 2) as cancellation_rate_pct
from monthly_cancellations c
left join monthly_sales s
    on c.revenue_month = s.revenue_month
order by revenue_month