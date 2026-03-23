select
    trip_id,
    flight_number,
    seat_number,
    count(*) as row_count
from {{ ref('fct_flight_booking') }}
group by 1, 2, 3
having count(*) > 1