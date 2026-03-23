select
    hotel_id::int as hotel_id,
    nullif(trim(hotel_name), '') as hotel_name,
    nullif(trim(hotel_address), '') as hotel_address,
    nullif(trim(city), '') as city,
    nullif(trim(country), '') as country,
    hotel_score::double precision as hotel_score
from {{ source('pactravel_raw', 'hotel') }}