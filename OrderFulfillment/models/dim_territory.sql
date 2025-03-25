with stg_vb_zip as
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
        'fudgetmart_v3' AS division
    FROM {{ source("fudgemart_v3", "fm_customers") }}
), stg_common_zip as (
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
)

select 
    * 
from stg_common_zip
