with service_type as (
    select * from {{ ref('dim_service_type') }}
),

flight_daily as (
    select
        f.departure_date_key as date_key,
        s.service_type_key,
        sum(f.booking_count)::int as total_bookings,
        sum(f.booking_amount)::numeric(18,2) as total_booking_amount
    from {{ ref('fct_flight_booking') }} f
    inner join service_type s
        on s.service_type_name = 'flight'
    group by 1, 2
),

hotel_daily as (
    select
        h.check_in_date_key as date_key,
        s.service_type_key,
        sum(h.booking_count)::int as total_bookings,
        sum(h.booking_amount)::numeric(18,2) as total_booking_amount
    from {{ ref('fct_hotel_booking') }} h
    inner join service_type s
        on s.service_type_name = 'hotel'
    group by 1, 2
)

select * from flight_daily
union all
select * from hotel_daily