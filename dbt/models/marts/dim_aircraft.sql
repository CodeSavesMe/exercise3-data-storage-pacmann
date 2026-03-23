with src as (
    select * from {{ ref('stg_aircrafts') }}
),

base as (
    select
        md5(aircraft_id) as aircraft_key,
        aircraft_id,
        aircraft_name,
        aircraft_iata,
        aircraft_icao
    from src
),

unknown_row as (
    select
        md5('-1') as aircraft_key,
        '-1'::text as aircraft_id,
        'Unknown Aircraft'::text as aircraft_name,
        null::text as aircraft_iata,
        null::text as aircraft_icao
)

select * from base
union all
select * from unknown_row