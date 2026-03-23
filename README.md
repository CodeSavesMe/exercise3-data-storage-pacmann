# PacTravel Data Warehouse

Proyek ini membangun **Data Warehouse PacTravel** menggunakan pendekatan **ELT (Extract, Load, Transform)** dengan tumpukan teknologi berikut:

* **PostgreSQL:** Sistem basis data untuk sumber operasional dan Data Warehouse (DWH).
* **Python:** Ekstraksi dan pemuatan data mentah (*raw load*).
* **dbt (Data Build Tool):** Transformasi data dan pemodelan dimensional.
* **Docker Compose:** Manajemen lingkungan lokal terisolasi.

## Objective

Tujuan utama dari proyek ini adalah:
* Membangun skema Data Warehouse terpusat.
* Mengimplementasikan *pipeline* ELT yang *reproducible*.
* Membangun *Star Schema* untuk memfasilitasi kebutuhan analitik.
* Menyediakan tabel *data mart* yang siap digunakan untuk pelaporan dan kueri bisnis.

## Business Scope

Dataset PacTravel mencakup dua proses bisnis utama:
1. **Flight Booking** (Pemesanan Penerbangan)
2. **Hotel Booking** (Pemesanan Hotel)

Kebutuhan analitik utama yang difasilitasi oleh Data Warehouse ini meliputi:
* Kalkulasi jumlah *booking*.
* Kalkulasi nilai *booking* (pendapatan).
* Analisis tren transaksi historis.
* Evaluasi performa maskapai.
* Evaluasi performa hotel.
* Analisis rute logistik penerbangan.
* Segmentasi demografis pelanggan.

## Architecture

*Pipeline* ELT beroperasi dengan alur pemrosesan berurutan sebagai berikut:

```text
[Source PostgreSQL]
        ↓
(Python Raw Loader)
        ↓
[DWH Raw Schema: `pactravel`]
        ↓
(dbt Staging Models)
        ↓
(dbt Snapshots & Mart Models)
        ↓
[Final Star Schema: `final`]
```

## Data Model

Lapisan final (*data mart*) dimodelkan menggunakan pendekatan **Star Schema** untuk mengoptimalkan kinerja kueri analitik.

### Fact Tables
* `fct_flight_booking`: Tabel fakta tingkat transaksi untuk penerbangan.
* `fct_hotel_booking`: Tabel fakta tingkat transaksi untuk hotel.
* `fct_daily_booking_summary`: Tabel fakta *periodic snapshot* untuk agregasi harian.

### Dimension Tables
* `dim_customer` (SCD Type 2)
* `dim_hotel` (SCD Type 2)
* `dim_airline`
* `dim_aircraft`
* `dim_airport`
* `dim_date`
* `dim_service_type`

## Quick Start

Ikuti langkah-langkah berikut untuk menjalankan *pipeline* di lingkungan lokal Anda.

**1. Persiapan Lingkungan (Setup Environment)**
```bash
cp .env.example .env
docker compose up -d
```

**2. Ekstraksi dan Pemuatan Data Mentah (Raw Load)**
```bash
uv run python -m pactravel_dwh.load_raw_to_dwh
```

**3. Transformasi Data (dbt Execution)**
```bash
cd dbt
dbt run --select models/staging
dbt snapshot
dbt run --select models/marts
dbt test
```

## Result Summary

### Pemuatan Data Mentah (Raw Load)
Seluruh data operasional berhasil diekstrak ke dalam skema *staging*.

| Source Table | Row Count |
| :--- | ---: |
| `customers` | 1,000 |
| `airlines` | 1,251 |
| `aircrafts` | 246 |
| `airports` | 105 |
| `hotel` | 1,470 |
| `flight_bookings` | 8,190 |
| `hotel_bookings` | 217 |

### Eksekusi dbt (Transform & Test)
Transformasi data dan pengujian kualitas (*data quality checks*) berhasil diselesaikan tanpa kesalahan.

* **Models:** 17
* **Snapshots:** 2
* **Sources:** 7
* **Data Tests:** 110
* **Status Keseluruhan:** PASS = 129 | WARN = 0 | ERROR = 0

## Project Structure

```text
.
├── data/                   # Skrip inisialisasi basis data (DDL/DML sumber)
├── dbt/                    # Proyek dbt (models, snapshots, tests, yml)
├── docs/                   # Dokumentasi teknis proyek
├── src/                    # Kode sumber Python untuk proses EL
├── docker-compose.yaml     # Konfigurasi layanan kontainer
├── pyproject.toml          # Manajemen dependensi Python
└── README.md               # Dokumentasi utama proyek
```

## Documentation

Detail penjelasan untuk setiap tahapan *pipeline* tersedia di dalam direktori `docs/`:

* `00_CASE_PACTRAVEL[pacmann].md`
* `01_requirements_gathering.md`
* `02_dimensional_model.md`
* `03_pipeline_design.md`
* `04_show_results_of_the_pipeline.md`


## Notes

* **Skema Sumber:** `public` (pada basis data operasional).
* **Skema Raw DWH:** `pactravel` (lapisan pendaratan data mentah).
* **Skema Final DWH:** `final` (lapisan *data mart* analitik).
* **Historisasi Data:** Perubahan dimensi ditangani menggunakan *dbt snapshots* (implementasi SCD Type 2).
* **Optimalisasi Kueri:** Analisis tren harian diselesaikan menggunakan *snapshot fact table* pada `fct_daily_booking_summary` untuk menghindari perhitungan ulang (*recalculation*) agregasi.

---



<div align="center">

### Mentoring - Exercise 3 - Data Storage
Dokumen ini dibuat sebagai bagian dari pembelajaran di <strong>Pacmann Academy Bootcamp</strong>.

<a href="https://pacmann.io">
  <img src="https://img.shields.io/badge/BOOTCAMP%20%7C%20PACMANN%20ACADEMY-0D3B66?style=for-the-badge&logoColor=white" alt="Pacmann Academy">
</a>

<a href="https://pacmann.io">pacmann.io</a>

</div>
