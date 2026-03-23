select
    date_key,
    service_type_key,
    count(*) as row_count
from {{ ref('fct_daily_booking_summary') }}
group by 1, 2
having count(*) > 1