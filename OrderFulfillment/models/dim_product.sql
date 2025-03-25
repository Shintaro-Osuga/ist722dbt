with stg_prod as 
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
    'vBay' AS division
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
)

select 
    *
from dim_common_prod