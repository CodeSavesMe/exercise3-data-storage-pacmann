with all_dates as (

    select departure_date as full_date
    from {{ ref('stg_flight_bookings') }}
    where departure_date is not null

    union

    select check_in_date as full_date
    from {{ ref('stg_hotel_bookings') }}
    where check_in_date is not null

    union

    select check_out_date as full_date
    from {{ ref('stg_hotel_bookings') }}
    where check_out_date is not null

)

select
    cast(to_char(full_date, 'YYYYMMDD') as integer) as date_key,
    full_date,
    extract(day from full_date)::int as day,
    extract(month from full_date)::int as month,
    trim(to_char(full_date, 'Month')) as month_name,
    extract(quarter from full_date)::int as quarter,
    extract(year from full_date)::int as year,
    extract(week from full_date)::int as week_of_year,
    trim(to_char(full_date, 'Day')) as day_of_week,
    case
        when extract(isodow from full_date) in (6, 7) then true
        else false
    end as is_weekend,
    to_char(full_date, 'YYYY-MM') as year_month
from all_dates