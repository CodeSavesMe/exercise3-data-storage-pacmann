{% snapshot snap_hotel %}

{{
    config(
      target_schema='snapshots',
      unique_key='hotel_id',
      strategy='check',
      check_cols=['hotel_name', 'hotel_address', 'city', 'country', 'hotel_score'],
      hard_deletes='invalidate'
    )
}}

select
    hotel_id,
    hotel_name,
    hotel_address,
    city,
    country,
    hotel_score
from {{ ref('stg_hotel') }}

{% endsnapshot %}