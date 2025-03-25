with stg_fm_customer as 
(
    select 
        customer_id as user_id,
        customer_email as user_email,
        customer_firstname as firstname,
        customer_lastname as lastname,
        customer_zip as zip,
        'fudgemart_v3' as division
    from {{ source("fudgemart_v3", 'fm_customers') }}
), stg_vb_customer as
(
    select
        user_id,
        user_email,
        user_firstname as firstname,
        user_lastname as lastname,
        user_zip_code as zip,
        'vbay' as division
    from {{ source("vbay", "vb_users") }}
), stg_common_customer as 
(
    select 
        user_id,
        user_email,
        firstname,
        lastname,
        zip,
        division
    from stg_fm_customer
        union all
        select 
            user_id,
            user_email,
            firstname,
            lastname,
            zip,
            division
        from stg_vb_customer
), stg_vb_date AS (

    SELECT
        i.item_id AS orderid,
        Replace(to_date(MIN(b.bid_datetime))::varchar,'-','')::int AS start_date,
        Replace(to_date(i.item_enddate)::varchar,'-','')::int AS end_date,
        0 AS time_diff, -- essentially 0 so therefore hardcode 0
        'vbay' AS division
    FROM {{ source("vbay", "vb_items") }} AS i
    LEFT JOIN {{ source("vbay", "vb_bids") }} AS b
        ON b.bid_item_id = i.item_id
    WHERE b.bid_datetime IS NOT NULL
        AND i.item_buyer_user_id IS NOT NULL
    GROUP BY i.item_id, i.item_enddate
), stg_fm_date as
(
SELECT
    order_id AS orderid,
    Replace(to_date(order_date)::varchar,'-','')::int AS start_date,
    Replace(to_date(shipped_date)::varchar,'-','')::int AS end_date,
    ((REPLACE(to_date(shipped_date)::varchar,'-','')::int) - (REPLACE(to_date(order_date)::varchar,'-','')::int)) AS time_diff,
    'fudgemart_v3' AS division
FROM {{ source("fudgemart_v3", "fm_orders") }}
), dim_common_table as ( -- THIS IS THE IMPORTANT ONE
        select orderid,
               start_date,
               end_date,
               time_diff,
               division
            from stg_vb_date
                union all 
                select orderid,
                    start_date,
                    end_date,
                    time_diff,
                    division
                from stg_fm_date
), stg_prod as 
(
SELECT
    ROW_NUMBER() OVER (ORDER BY p.product_id) AS product_key,
    p.product_id AS product_id,
    p.product_name AS product_name,
    p.product_department AS product_type,
    p.product_retail_price AS product_price,
    'fudgemart_v3' AS division
FROM {{ source("fudgemart_v3", "fm_products") }} p
), stg_fm_prod as
(
SELECT
    ROW_NUMBER() OVER (ORDER BY i.item_id) AS product_key,
    i.item_id AS product_id,
    i.item_name AS product_name,
    i.item_type AS product_type,
    i.item_reserve AS product_price,
    'vbay' AS division
FROM {{ source("vbay", "vb_items") }} i
), dim_common_prod as (
    select 
        product_key,
        product_id,
        product_name,
        product_type,
        product_price,
        division
    from stg_prod
    union all 
        select 
            product_key,
            product_id,
            product_name,
            product_type,
            product_price,
            division
        from stg_fm_prod
), stg_vb_zip as
(
    SELECT
        DISTINCT zip_code AS Zip_code,
        zip_city AS Zip_City,
        zip_state AS Zip_State,
        'vbay' AS division
    FROM {{ source("vbay", "vb_zip_codes") }}
), stg_fm_zip as
(
    SELECT
        DISTINCT customer_zip AS Zip_code,
        customer_city AS Zip_City,
        customer_state AS Zip_State,
        'fudgemart_v3' AS division
    FROM {{ source("fudgemart_v3", "fm_customers") }}
), stg_common_zip as ( -- im
    select 
        zip_code,
        zip_city,
        zip_state,
        division
    from stg_vb_zip
    union all 
    select
        zip_code,
        zip_city,
        zip_state,
        division
    from stg_fm_zip
), stg_employees as (
    select 
        vendor_id as user_id,
        vendor_name as username,
        'fudgemart_v3' as division
     from {{source('fudgemart_v3','fm_vendors')}}
),
stg_vb_vendor as (
    select 
        u.user_id,
        u.user_firstname as username,
        'vbay' as division
     from {{source('vbay','vb_users')}} u
        inner join {{ source("vbay", "vb_user_ratings") }} as r
            on u.user_id = r.rating_for_user_id
), stg_common_ven as ( --IMPORTANT ONE
    select 
        user_id,
        username,
        division
    from stg_employees
    union all
    select        
        user_id,
        username,
        division
    from stg_vb_vendor
), stg_fm_order as
(
select od.order_id,
    od.product_id,
    'fudgemart_v3' as division,
    o.customer_id
    from {{ source('fudgemart_v3', 'fm_order_details')}} od
        left join {{ source('fudgemart_v3', 'fm_orders') }} o
            on od.order_id = o.order_id
), stg_vb_order as (
    select item_id as order_id,
           item_id as product_id,
           'vbay' as division,
           item_buyer_user_id as customer_id
        from {{ source('vbay','vb_items')}}
           
), stg_common_order as (
    select order_id,
            product_id,
            customer_id,
            division
        from stg_fm_order
            union all 
            select order_id,
                product_id,
                customer_id,
                division
            from stg_vb_order
)

select  d.orderid, -- date
        d.start_date,
        d.end_date,
        d.time_diff,
        d.division,
        o.product_id, -- order
        o.customer_id,
        p.product_name, -- product
        p.product_type,
        p.product_price,
        c.user_id, -- customer
        c.user_email,
        concat(c.lastname, ',', c.firstname) as namefirstlast,
        concat(c.firstname, ',', c.lastname) as namelastfirst,
        c.zip,
        v.username as vendor_username,
        v.user_id as vendor_id,
        z.zip_city,
        z.zip_state
from dim_common_table as d
    left join stg_common_order o
        on d.orderid = o.order_id and d.division = o.division
    left join dim_common_prod as p
        on o.product_id = p.product_id and o.division = p.division
    left join stg_common_customer as c
        on o.customer_id = c.user_id and o.division = c.division
    left join stg_common_ven as v
        on v.user_id = c.user_id and v.division = c.division
    left join stg_common_zip as z
        on z.zip_code = c.zip and z.division = o.division
