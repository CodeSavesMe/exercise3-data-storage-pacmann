select
    airport_id::int as airport_id,
    nullif(trim(airport_name), '') as airport_name,
    nullif(trim(city), '') as city,
    latitude::double precision as latitude,
    longitude::double precision as longitude
from {{ source('pactravel_raw', 'airports') }}