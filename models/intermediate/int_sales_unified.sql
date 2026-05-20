with sales as (
    select * from {{ ref('stg_sales') }}
),

cancellations as (
    select * from {{ ref('stg_cancellations') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

sales_enriched as (
    select
        s.invoice_no,
        s.stock_code,
        s.product_description,
        s.quantity,
        s.invoice_date,
        s.unit_price,
        s.revenue,
        s.channel,
        s.country,
        c.customer_id,
        false as is_cancellation
    from sales s
    left join customers c
        on s.customer_id = c.customer_id
),

cancellations_enriched as (
    select
        ca.invoice_no,
        ca.stock_code,
        ca.product_description,
        ca.quantity_cancelled      as quantity,
        ca.cancelled_at            as invoice_date,
        ca.unit_price,
        ca.revenue_lost            as revenue,
        'online_store'             as channel,
        ca.country,
        c.customer_id,
        true                       as is_cancellation
    from cancellations ca
    left join customers c
        on ca.customer_id = c.customer_id
),

unified as (
    select * from sales_enriched
    union all
    select * from cancellations_enriched
)

select * from unified 