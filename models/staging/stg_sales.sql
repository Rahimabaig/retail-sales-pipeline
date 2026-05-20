with source as (
    select *    
    from {{ source('raw_data', 'raw_sales') }}
),

cleaned as (
    select
        invoiceno                                               as invoice_no,
        stockcode                                               as stock_code,
        trim(description)                                       as product_description,
        quantity                                                as quantity,
        invoicedate                                             as invoice_date,
        cast(unitprice as float)                                as unit_price,
        coalesce(trim(cast(customerid as string)), 'unknown')   as customer_id,
        trim(country)                                           as country,
        quantity * unitprice                                    as revenue,
        'online_store'                                          as channel
    from source
    where quantity > 0
      and unitprice > 0
)

select * from cleaned