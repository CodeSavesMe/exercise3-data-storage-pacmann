with src as (
    select * from {{ ref('stg_airlines') }}
),

base as (
    select
        md5(airline_id::text) as airline_key,
        airline_id,
        airline_name,
        country,
        airline_iata,
        airline_icao,
        alias
    from src
),

unknown_row as (
    select
        md5('-1') as airline_key,
        -1::int as airline_id,
        'Unknown Airline'::text as airline_name,
        null::text as country,
        null::text as airline_iata,
        null::text as airline_icao,
        null::text as alias
)

select * from base
union all
select * from unknown_row