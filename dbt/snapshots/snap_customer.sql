{% snapshot snap_customer %}

{{
    config(
      target_schema='snapshots',
      unique_key='customer_id',
      strategy='check',
      check_cols=['customer_country', 'customer_phone_number'],
      hard_deletes='invalidate'
    )
}}

select
    customer_id,
    customer_first_name,
    customer_family_name,
    customer_gender,
    customer_birth_date,
    customer_country,
    customer_phone_number
from {{ ref('stg_customers') }}

{% endsnapshot %}