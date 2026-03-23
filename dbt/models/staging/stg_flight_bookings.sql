select
    trip_id::int as trip_id,
    customer_id::int as customer_id,
    nullif(trim(flight_number), '') as flight_number,
    airline_id::int as airline_id,
    nullif(trim(aircraft_id), '') as aircraft_id,
    airport_src::int as airport_src,
    airport_dst::int as airport_dst,
    departure_time::time as departure_time,
    departure_date::date as departure_date,
    nullif(trim(flight_duration), '') as flight_duration,
    nullif(trim(travel_class), '') as travel_class,
    nullif(trim(seat_number), '') as seat_number,
    price::numeric(18,2) as price
from {{ source('pactravel_raw', 'flight_bookings') }}