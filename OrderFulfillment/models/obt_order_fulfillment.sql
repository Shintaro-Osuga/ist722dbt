with f_order_fulfillment as (
    select * from {{ ref("fact_order_fulfillment") }}
),
d_customer as (
    select * from {{ ref("dim_customer") }}
),
d_date as (
    select * from {{ ref("dim_date") }}
)
,
d_order as (
    select * from {{ ref("dim_order") }}
)
,
d_product as (
    select * from {{ ref("dim_product") }}
)
,
d_territory as (
    select * from {{ ref("dim_territory") }}
)
,
d_vendor as (
    select * from {{ ref("dim_vendor") }}
)
select
    f.orderid,
    f.start_date,
    f.end_date,
    f.time_diff,
    f.division,
    f.product_id,
    f.customer_id,
    f.product_name,
    f.product_type,
    f.product_price,
    f.user_id,
    f.user_email,
    f.namefirstlast,
    f.namelastfirst,
    f.zip,
    f.vendor_username,
    f.vendor_id,
    f.zip_city,
    f.zip_state
    from f_order_fulfillment as f
    left join d_customer on f.user_id = d_customer.user_id and f.division = d_customer.division
    left join d_date on f.order_id = d_date.orderid and f.division = d_date.division
    left join d_order on f.order_id = d_order.order_id and f.division = d_order.division
    left join d_product on f.product_id = d_product.product_id and f.division = d_product.division
    left join d_territory on f.zip = d_territory.zip_code and f.division = d_territory.division
    left join d_vendor on f.vendor_id = d_vendor.user_id and f.division = d_vendor.division
