with src as (
    select * from {{ ref('snap_customer') }}
),

base as (
    select
        md5(customer_id::text || '|' || coalesce(dbt_valid_from::text, '')) as customer_key,
        customer_id,
        customer_first_name,
        customer_family_name,
        customer_gender,
        customer_birth_date,
        customer_country,
        customer_phone_number,
        dbt_valid_from::timestamp as valid_from,
        dbt_valid_to::timestamp as valid_to,
        (dbt_valid_to is null) as is_current
    from src
),

unknown_row as (
    select
        md5('-1|unknown') as customer_key,
        -1::int as customer_id,
        'Unknown'::text as customer_first_name,
        null::text as customer_family_name,
        null::text as customer_gender,
        null::date as customer_birth_date,
        null::text as customer_country,
        null::bigint as customer_phone_number,
        '1900-01-01'::timestamp as valid_from,
        null::timestamp as valid_to,
        true as is_current
)

select * from base
union all
select * from unknown_row