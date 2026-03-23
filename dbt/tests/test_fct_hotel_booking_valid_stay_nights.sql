select *
from {{ ref('fct_hotel_booking') }}
where stay_nights < 0