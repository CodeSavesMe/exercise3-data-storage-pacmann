with src as (
    select * from {{ ref('snap_hotel') }}
),

base as (
    select
        md5(hotel_id::text || '|' || coalesce(dbt_valid_from::text, '')) as hotel_key,
        hotel_id,
        hotel_name,
        hotel_address,
        city,
        country,
        hotel_score,
        dbt_valid_from::timestamp as valid_from,
        dbt_valid_to::timestamp as valid_to,
        (dbt_valid_to is null) as is_current
    from src
),

unknown_row as (
    select
        md5('-1|unknown') as hotel_key,
        -1::int as hotel_id,
        'Unknown Hotel'::text as hotel_name,
        null::text as hotel_address,
        null::text as city,
        null::text as country,
        null::double precision as hotel_score,
        '1900-01-01'::timestamp as valid_from,
        null::timestamp as valid_to,
        true as is_current
)

select * from base
union all
select * from unknown_row