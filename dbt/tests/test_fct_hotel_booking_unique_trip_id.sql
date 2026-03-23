select
    trip_id,
    count(*) as row_count
from {{ ref('fct_hotel_booking') }}
group by 1
having count(*) > 1