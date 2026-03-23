with src as (
    select * from {{ ref('stg_flight_bookings') }}
),

dim_customer_current as (
    select *
    from {{ ref('dim_customer') }}
    where is_current = true
),

dim_airline as (
    select * from {{ ref('dim_airline') }}
),

dim_aircraft as (
    select * from {{ ref('dim_aircraft') }}
),

dim_airport as (
    select * from {{ ref('dim_airport') }}
),

dim_date as (
    select * from {{ ref('dim_date') }}
),

unknown_keys as (
    select
        md5('-1|unknown') as unknown_customer_key,
        md5('-1') as unknown_airline_key,
        md5('-1') as unknown_aircraft_key,
        md5('-1') as unknown_airport_key
)

select
    md5(
        coalesce(s.trip_id::text, '') || '|' ||
        coalesce(s.flight_number, '') || '|' ||
        coalesce(s.seat_number, '')
    ) as flight_booking_line_key,

    coalesce(dc.customer_key, uk.unknown_customer_key) as customer_key,
    coalesce(da.airline_key, uk.unknown_airline_key) as airline_key,
    coalesce(dac.aircraft_key, uk.unknown_aircraft_key) as aircraft_key,
    coalesce(das.airport_key, uk.unknown_airport_key) as airport_src_key,
    coalesce(dad.airport_key, uk.unknown_airport_key) as airport_dst_key,
    dd.date_key as departure_date_key,

    s.trip_id,
    s.customer_id,
    s.flight_number,
    s.seat_number,
    s.travel_class,
    s.departure_time,
    s.departure_date,
    s.flight_duration,

    coalesce(s.price, 0)::numeric(18,2) as booking_amount,
    1::int as booking_count
from src s
cross join unknown_keys uk
left join dim_customer_current dc
    on s.customer_id = dc.customer_id
left join dim_airline da
    on s.airline_id = da.airline_id
left join dim_aircraft dac
    on s.aircraft_id = dac.aircraft_id
left join dim_airport das
    on s.airport_src = das.airport_id
left join dim_airport dad
    on s.airport_dst = dad.airport_id
left join dim_date dd
    on s.departure_date = dd.full_date