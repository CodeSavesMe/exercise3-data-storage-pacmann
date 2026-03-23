select
    airline_id::int as airline_id,
    nullif(trim(airline_name), '') as airline_name,
    nullif(trim(country), '') as country,
    nullif(trim(airline_iata), '') as airline_iata,
    nullif(trim(airline_icao), '') as airline_icao,
    nullif(trim(alias), '') as alias
from {{ source('pactravel_raw', 'airlines') }}