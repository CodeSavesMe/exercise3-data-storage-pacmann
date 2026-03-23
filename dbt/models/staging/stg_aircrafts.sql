select
    nullif(trim(aircraft_id), '') as aircraft_id,
    nullif(trim(aircraft_name), '') as aircraft_name,
    nullif(trim(aircraft_iata), '') as aircraft_iata,
    nullif(trim(aircraft_icao), '') as aircraft_icao
from {{ source('pactravel_raw', 'aircrafts') }}