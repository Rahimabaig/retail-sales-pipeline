with source as (
    select * from {{ source('raw_data', 'raw_cancellations') }}
),

cleaned as (
    select
        invoiceno                                               as invoice_no,
        stockcode                                               as stock_code,
        trim(description)                                       as product_description,
        abs(quantity)                                           as quantity_cancelled,
        invoicedate                                             as cancelled_at,
        unitprice                                               as unit_price,
        coalesce(trim(cast(customerid as string)), 'unknown')   as customer_id,
        trim(country)                                           as country,
        round(abs(quantity * unitprice), 2)                     as revenue_lost
    from source
)

select * from cleaned