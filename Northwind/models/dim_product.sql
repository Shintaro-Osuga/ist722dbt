with stg_products as (
    select * from {{ source('northwind','Products')}}
)
select {{ dbt_utils.generate_surrogate_key(["stg_products.productid"]) }} as productkey,
    stg_products.*
from stg_products