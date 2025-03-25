with stg_fm_order as
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

select * from stg_common_order