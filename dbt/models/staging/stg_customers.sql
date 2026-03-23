select
    customer_id::int as customer_id,
    nullif(trim(customer_first_name), '') as customer_first_name,
    nullif(trim(customer_family_name), '') as customer_family_name,
    nullif(trim(customer_gender), '') as customer_gender,
    customer_birth_date::date as customer_birth_date,
    nullif(trim(customer_country), '') as customer_country,
    customer_phone_number::bigint as customer_phone_number
from {{ source('pactravel_raw', 'customers') }}