with src as (
    select * from {{ ref('stg_hotel_bookings') }}
),

dim_customer_current as (
    select *
    from {{ ref('dim_customer') }}
    where is_current = true
),

dim_hotel_current as (
    select *
    from {{ ref('dim_hotel') }}
    where is_current = true
),

dim_date as (
    select * from {{ ref('dim_date') }}
),

unknown_keys as (
    select
        md5('-1|unknown') as unknown_customer_key,
        md5('-1|unknown') as unknown_hotel_key
)

select
    md5(coalesce(s.trip_id::text, '')) as hotel_booking_key,

    coalesce(dc.customer_key, uk.unknown_customer_key) as customer_key,
    coalesce(dh.hotel_key, uk.unknown_hotel_key) as hotel_key,
    dci.date_key as check_in_date_key,
    dco.date_key as check_out_date_key,

    s.trip_id,
    s.customer_id,
    s.hotel_id,
    s.check_in_date,
    s.check_out_date,
    s.breakfast_included,

    coalesce(s.price, 0)::numeric(18,2) as booking_amount,
    1::int as booking_count,
    greatest((s.check_out_date - s.check_in_date), 0)::int as stay_nights
from src s
cross join unknown_keys uk
left join dim_customer_current dc
    on s.customer_id = dc.customer_id
left join dim_hotel_current dh
    on s.hotel_id = dh.hotel_id
left join dim_date dci
    on s.check_in_date = dci.full_date
left join dim_date dco
    on s.check_out_date = dco.full_date