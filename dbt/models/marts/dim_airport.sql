with src as (
    select * from {{ ref('stg_airports') }}
),

base as (
    select
        md5(airport_id::text) as airport_key,
        airport_id,
        airport_name,
        city,
        latitude,
        longitude
    from src
),

unknown_row as (
    select
        md5('-1') as airport_key,
        -1::int as airport_id,
        'Unknown Airport'::text as airport_name,
        null::text as city,
        null::double precision as latitude,
        null::double precision as longitude
)

select * from base
union all
select * from unknown_row