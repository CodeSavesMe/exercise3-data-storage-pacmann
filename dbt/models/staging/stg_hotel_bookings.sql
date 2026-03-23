select
    trip_id::int as trip_id,
    customer_id::int as customer_id,
    hotel_id::int as hotel_id,
    check_in_date::date as check_in_date,
    check_out_date::date as check_out_date,
    price::numeric(18,2) as price,
    breakfast_included::boolean as breakfast_included
from {{ source('pactravel_raw', 'hotel_bookings') }}