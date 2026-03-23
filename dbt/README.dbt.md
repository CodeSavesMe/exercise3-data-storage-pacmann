# PacTravel Data Warehouse — dbt Layer

**Tools:** dbt Core • Postgres
**Layer:** Staging → Snapshots → Marts
**Approach:** ELT (Python/Luigi + dbt) • Star Schema • SCD Type 2 + Unknown Member

---

## Overview

Bagian ini merupakan layer Analytics Engineering dari Data Warehouse PacTravel yang dibangun menggunakan dbt.

Pipeline mengikuti arsitektur:

```text
Source DB (OLTP)
   ↓
Python + Luigi (Extract & Load)
   ↓
DWH (schema: pactravel)
   ↓
dbt (Transform)
   ↓
DWH (schema: staging, snapshots, final)
```

dbt digunakan untuk:

* Membersihkan dan menstandarkan data (staging)
* Mengelola histori perubahan (SCD Type 2 via snapshots)
* Membangun dimensional model (Star Schema)
* Menyediakan data siap analitik

---

## Data Layer Architecture

| Layer     | Schema    | Deskripsi                         |
| --------- | --------- | --------------------------------- |
| Raw       | pactravel | Data hasil load dari Python/Luigi |
| Staging   | staging   | Cleaning dan standardisasi        |
| Snapshots | snapshots | SCD Type 2 historization          |
| Marts     | final     | Dimensi dan fact siap analitik    |

---

## Project Structure

```text
dbt/
├── dbt_project.yml
├── profiles.yml
├── macros/
│   └── generate_schema_name.sql
├── models/
│   ├── sources.yml
│   ├── staging/
│   └── marts/
├── snapshots/
└── tests/
```

---

## Source Configuration

Semua data dibaca dari schema:

```yaml
schema: pactravel
```

Tabel source:

* customers
* airlines
* aircrafts
* airports
* hotel
* flight_bookings
* hotel_bookings

---

## Staging Layer

Fungsi:

* Casting tipe data
* Membersihkan string (trim, nullif)
* Standardisasi kolom

Contoh:

```sql
select
    customer_id::int as customer_id,
    nullif(trim(customer_first_name), '') as customer_first_name
from {{ source('pactravel_raw', 'customers') }}
```

---

## Snapshots (SCD Type 2)

Digunakan untuk:

* dim_customer
* dim_hotel

Strategi:

```yaml
strategy: check
check_cols:
  - customer_country
  - customer_phone_number
```

Output:

* valid_from
* valid_to
* is_current

Catatan:
Karena source tidak memiliki updated_at, perubahan dideteksi berdasarkan perubahan nilai kolom.

---

## Dimensional Model (Star Schema)

### Dimensions

| Dimension        | Tipe       |
| ---------------- | ---------- |
| dim_customer     | SCD Type 2 |
| dim_hotel        | SCD Type 2 |
| dim_airline      | Type 1     |
| dim_aircraft     | Type 1     |
| dim_airport      | Type 1     |
| dim_date         | Static     |
| dim_service_type | Static     |

---

## Unknown Member Strategy

Untuk menjaga integritas referensial:

* Semua dimension memiliki unknown member
* Default key:

  * -1 (business key)
  * md5('-1') (surrogate key)

Digunakan saat:

* data source tidak match ke dimension
* missing reference

Contoh:

```sql
coalesce(dim_key, md5('-1'))
```

---

## Fact Tables

### 1. fct_flight_booking (Transaction Fact)

Grain:
Satu baris merepresentasikan satu flight booking line untuk satu customer pada satu trip, satu flight number, dan satu seat.

Measures:

* booking_amount
* booking_count

---

### 2. fct_hotel_booking (Transaction Fact)

Grain:
Satu baris merepresentasikan satu hotel booking per trip.

Measures:

* booking_amount
* booking_count
* stay_nights

---

### 3. fct_daily_booking_summary (Periodic Snapshot Fact)

Grain:
Satu baris merepresentasikan agregasi harian per service type.

| Service | Date Source    |
| ------- | -------------- |
| Flight  | departure_date |
| Hotel   | check_in_date  |

Catatan:
Dataset tidak memiliki booking_created_at, sehingga digunakan service date, bukan transaction date.

---

## Join Strategy

### SCD Dimensions (Customer dan Hotel)

Fact menggunakan:

```sql
where is_current = true
```

Alasan:

* Snapshot dibuat saat pipeline dijalankan
* Tidak mencerminkan histori perubahan yang sebenarnya
* Range join tidak valid untuk dataset ini

---

### Non-SCD Dimensions

* Join menggunakan business key
* Fallback ke unknown member jika tidak match

---

## Testing Strategy

### Built-in Tests

* not_null
* unique
* relationships
* accepted_values

### Custom Tests

#### Grain check

```sql
trip_id + flight_number + seat_number
```

#### SCD overlap check

```sql
valid_to > next_valid_from
```

#### Business rule

```sql
stay_nights >= 0
```

---

## How to Run

### Install dependencies

```bash
uv sync
```

---

### Run pipeline

```bash
uv run dbt run --select staging
uv run dbt snapshot
uv run dbt run --select marts
uv run dbt test
```

---

## Output Tables

Schema final:

* dim_customer
* dim_hotel
* dim_airline
* dim_aircraft
* dim_airport
* dim_date
* dim_service_type
* fct_flight_booking
* fct_hotel_booking
* fct_daily_booking_summary

---

## Limitations

1. Source tidak memiliki updated_at
2. Snapshot tidak mencerminkan histori real-time
3. Fact tidak menggunakan range join historis
4. Periodic snapshot menggunakan service date, bukan booking date

---

## Future Improvements

* Tambahkan booking_created_at pada source
* Gunakan incremental model di dbt
* Tambahkan data quality alert
* Integrasi BI dashboard
* Implementasi surrogate key global

---

## Key Takeaways

* Memisahkan ingestion dan transformasi
* Menggunakan SCD Type 2 untuk histori dimensi
* Menggunakan unknown member untuk menjaga stabilitas pipeline
* Menggunakan Star Schema untuk kebutuhan analitik

---

## Repository

Tambahkan link repository di sini.
