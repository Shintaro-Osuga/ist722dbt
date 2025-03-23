WITH stg_vb_date AS (

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
    'fudgemart' AS division
FROM {{ source("fudgemart_v3", "fm_orders") }}
),
    dim_common_table as (
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
    )

select * from dim_common_table
