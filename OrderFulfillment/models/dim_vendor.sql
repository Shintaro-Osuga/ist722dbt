with stg_employees as (
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
), stg_common_ven as (
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
)


select 
    {{ dbt_utils.generate_surrogate_key(['e.user_id']) }} as employeekey,
    e.user_id,
    e.username,
    e.division
from stg_common_ven e
