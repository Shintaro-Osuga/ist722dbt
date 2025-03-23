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
)

select * from stg_common_customer