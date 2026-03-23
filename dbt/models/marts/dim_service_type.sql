select
    md5('flight') as service_type_key,
    'flight'::text as service_type_name

union all

select
    md5('hotel') as service_type_key,
    'hotel'::text as service_type_name