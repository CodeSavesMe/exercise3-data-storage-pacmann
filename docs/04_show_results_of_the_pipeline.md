
## Step #4 — Show Results of the Pipeline

### 1. Hasil Eksekusi Pipeline
Pipeline telah dijalankan secara keseluruhan dengan alur pemrosesan sebagai berikut:
1. Ekstraksi data dari sumber PostgreSQL.
2. Pemuatan data mentah ke skema raw `pactravel` pada Data Warehouse menggunakan skrip Python.
3. Transformasi data ke skema `staging` dan `final` menggunakan dbt.
4. Eksekusi proses *snapshot* dan *data quality tests*.

Seluruh tabel utama telah berhasil diekstrak dari skema `public` pada sumber dan dimuat ke skema raw Data Warehouse tanpa indikasi kesalahan.

**Hasil Pemuatan Data Mentah (Raw Load):**

| Table | Row Count |
| :--- | ---: |
| `customers` | 1000 |
| `airlines` | 1251 |
| `aircrafts` | 246 |
| `airports` | 105 |
| `hotel` | 1470 |
| `flight_bookings` | 8190 |
| `hotel_bookings` | 217 |

---

### 2. Hasil Tabel Final
Setelah pemuatan data mentah selesai, dbt telah menyusun tabel analitik pada skema `final` sesuai dengan desain model dimensional pada Step #2.

**Dimension Tables:**
* `final.dim_customer`
* `final.dim_airline`
* `final.dim_aircraft`
* `final.dim_airport`
* `final.dim_hotel`
* `final.dim_date`
* `final.dim_service_type`

**Fact Tables:**
* `final.fct_flight_booking` (Tabel fakta transaksi tingkat *booking* penerbangan)
* `final.fct_hotel_booking` (Tabel fakta transaksi tingkat *booking* hotel)
* `final.fct_daily_booking_summary` (Tabel fakta *periodic snapshot* untuk analisis tren harian)

**Baris Data Tabel Final Utama:**

| Table | Row Count |
| :--- | ---: |
| `final.dim_service_type` | 2 |
| `final.dim_date` | 2358 |
| `final.fct_flight_booking` | 8190 |
| `final.fct_hotel_booking` | 217 |
| `final.fct_daily_booking_summary` | 2548 |

---

### 3. Validasi Hasil Transformasi
Transformasi dbt dieksekusi secara penuh untuk memastikan struktur dan kualitas data. 

**Ringkasan Hasil Eksekusi dbt:**
* **Models:** 17
* **Snapshots:** 2
* **Data Tests:** 110
* **Sources:** 7

**Status Akhir Uji Kualitas Data:**
* PASS: 129
* WARN: 0
* ERROR: 0

Hal ini menunjukkan model *staging*, *snapshot* untuk `dim_customer` dan `dim_hotel`, serta tabel *dimension* dan *fact* berhasil dibangun. Seluruh pengujian kualitas data lolos tanpa kegagalan.

**Validasi Spesifik yang Berhasil Dilalui:**
* `fct_flight_booking` dan `fct_daily_booking_summary` lolos uji parameter *unique grain*.
* `fct_hotel_booking` lolos uji parameter *unique trip_id* dan parameter *valid stay_nights*.
* `dim_customer` dan `dim_hotel` lolos uji *no overlapping ranges* untuk histori dimensi tipe 2.
* Uji integritas referensial (*relationship test*) antara tabel fakta dan dimensi lolos sepenuhnya.

---

### 4. Contoh Query Hasil Pipeline
Kueri berikut menunjukkan contoh data dari tabel final yang berhasil dibangun.

**A. Contoh data fact booking penerbangan**
Kueri ini menampilkan contoh data detail *booking* penerbangan pada tingkat *grain* transaksi.
```sql
SELECT *
FROM final.fct_flight_booking
LIMIT 10;
```

**B. Contoh data fact booking hotel**
Kueri ini menampilkan contoh data detail *booking* hotel.
```sql
SELECT *
FROM final.fct_hotel_booking
LIMIT 10;
```

**C. Contoh data fact snapshot harian**
Kueri ini menampilkan agregasi harian per jenis layanan.
```sql
SELECT *
FROM final.fct_daily_booking_summary
ORDER BY date_key, service_type_key
LIMIT 20;
```

---

### 5. Contoh Query Analitik
Kueri analitik berikut menunjukkan kesiapan Data Warehouse untuk proses pelaporan tingkat lanjut.

**A. Total booking per jenis layanan**
Kueri ini membandingkan total *booking* dan nilai keseluruhan antara layanan *flight* dan hotel.
```sql
SELECT
    s.service_type_name,
    SUM(f.total_bookings) AS total_bookings,
    SUM(f.total_booking_amount) AS total_booking_amount
FROM final.fct_daily_booking_summary f
JOIN final.dim_service_type s
    ON f.service_type_key = s.service_type_key
GROUP BY s.service_type_name
ORDER BY total_booking_amount DESC;
```

**B. Tren booking harian flight vs hotel**
Kueri ini memetakan tren jumlah dan nilai *booking* harian berdasarkan jenis layanan.
```sql
SELECT
    d.full_date,
    s.service_type_name,
    f.total_bookings,
    f.total_booking_amount
FROM final.fct_daily_booking_summary f
JOIN final.dim_date d
    ON f.date_key = d.date_key
JOIN final.dim_service_type s
    ON f.service_type_key = s.service_type_key
ORDER BY d.full_date, s.service_type_name;
```

**C. Total booking dan nilai booking per maskapai**
Kueri ini mengidentifikasi maskapai dengan tingkat pemesanan tertinggi.
```sql
SELECT
    a.airline_name,
    SUM(f.booking_count) AS total_bookings,
    SUM(f.booking_amount) AS total_booking_amount
FROM final.fct_flight_booking f
JOIN final.dim_airline a
    ON f.airline_key = a.airline_key
GROUP BY a.airline_name
ORDER BY total_booking_amount DESC;
```

**D. Total booking dan nilai booking per hotel**
Kueri ini mengidentifikasi hotel dengan kontribusi pemesanan tertinggi.
```sql
SELECT
    h.hotel_name,
    SUM(f.booking_count) AS total_bookings,
    SUM(f.booking_amount) AS total_booking_amount
FROM final.fct_hotel_booking f
JOIN final.dim_hotel h
    ON f.hotel_key = h.hotel_key
GROUP BY h.hotel_name
ORDER BY total_booking_amount DESC;
```

**E. Rute penerbangan paling populer**
Kueri ini menampilkan rute logistik dengan frekuensi pemesanan tertinggi.
```sql
SELECT
    src.airport_name AS airport_source,
    dst.airport_name AS airport_destination,
    SUM(f.booking_count) AS total_bookings,
    SUM(f.booking_amount) AS total_booking_amount
FROM final.fct_flight_booking f
JOIN final.dim_airport src
    ON f.airport_src_key = src.airport_key
JOIN final.dim_airport dst
    ON f.airport_dst_key = dst.airport_key
GROUP BY src.airport_name, dst.airport_name
ORDER BY total_bookings DESC, total_booking_amount DESC;
```

**F. Segmentasi customer berdasarkan negara**
Kueri ini memetakan distribusi nilai transaksi berdasarkan negara asal pelanggan.
```sql
SELECT
    c.customer_country,
    SUM(f.booking_count) AS total_flight_bookings,
    SUM(f.booking_amount) AS total_flight_booking_amount
FROM final.fct_flight_booking f
JOIN final.dim_customer c
    ON f.customer_key = c.customer_key
GROUP BY c.customer_country
ORDER BY total_flight_booking_amount DESC;
```

---

### 6. Alternatif Menjalankan Query Analitik via Docker Exec
Selain menggunakan aplikasi klien basis data (seperti pgAdmin), kueri analitik dan pengecekan data sampel dapat dieksekusi secara langsung dari *container* PostgreSQL Data Warehouse melalui antarmuka baris perintah (CLI). Pendekatan ini memungkinkan verifikasi hasil *pipeline* tanpa memerlukan perangkat tambahan pada sistem lokal.

**Mengakses shell interaktif psql:**
```bash
docker compose exec dwh_db psql -U postgres -d pactravel-dwh
```
*(Setelah masuk, kueri SQL pada bagian 4 dan 5 dapat dijalankan secara langsung).*

**Mengeksekusi kueri langsung tanpa masuk ke shell interaktif:**

**A. Total booking per jenis layanan**
```bash
docker compose exec dwh_db psql -U postgres -d pactravel-dwh -c "
SELECT
    s.service_type_name,
    SUM(f.total_bookings) AS total_bookings,
    SUM(f.total_booking_amount) AS total_booking_amount
FROM final.fct_daily_booking_summary f
JOIN final.dim_service_type s
    ON f.service_type_key = s.service_type_key
GROUP BY s.service_type_name
ORDER BY total_booking_amount DESC;
"
```

**B. Tren booking harian flight vs hotel**
```bash
docker compose exec dwh_db psql -U postgres -d pactravel-dwh -c "
SELECT
    d.full_date,
    s.service_type_name,
    f.total_bookings,
    f.total_booking_amount
FROM final.fct_daily_booking_summary f
JOIN final.dim_date d
    ON f.date_key = d.date_key
JOIN final.dim_service_type s
    ON f.service_type_key = s.service_type_key
ORDER BY d.full_date, s.service_type_name;
"
```

**C. Total booking dan nilai booking per maskapai**
```bash
docker compose exec dwh_db psql -U postgres -d pactravel-dwh -c "
SELECT
    a.airline_name,
    SUM(f.booking_count) AS total_bookings,
    SUM(f.booking_amount) AS total_booking_amount
FROM final.fct_flight_booking f
JOIN final.dim_airline a
    ON f.airline_key = a.airline_key
GROUP BY a.airline_name
ORDER BY total_booking_amount DESC;
"
```

**D. Total booking dan nilai booking per hotel**
```bash
docker compose exec dwh_db psql -U postgres -d pactravel-dwh -c "
SELECT
    h.hotel_name,
    SUM(f.booking_count) AS total_bookings,
    SUM(f.booking_amount) AS total_booking_amount
FROM final.fct_hotel_booking f
JOIN final.dim_hotel h
    ON f.hotel_key = h.hotel_key
GROUP BY h.hotel_name
ORDER BY total_booking_amount DESC;
"
```

**E. Rute penerbangan paling populer**
```bash
docker compose exec dwh_db psql -U postgres -d pactravel-dwh -c "
SELECT
    src.airport_name AS airport_source,
    dst.airport_name AS airport_destination,
    SUM(f.booking_count) AS total_bookings,
    SUM(f.booking_amount) AS total_booking_amount
FROM final.fct_flight_booking f
JOIN final.dim_airport src
    ON f.airport_src_key = src.airport_key
JOIN final.dim_airport dst
    ON f.airport_dst_key = dst.airport_key
GROUP BY src.airport_name, dst.airport_name
ORDER BY total_bookings DESC, total_booking_amount DESC;
"
```

**F. Segmentasi customer berdasarkan negara**
```bash
docker compose exec dwh_db psql -U postgres -d pactravel-dwh -c "
SELECT
    c.customer_country,
    SUM(f.booking_count) AS total_flight_bookings,
    SUM(f.booking_amount) AS total_flight_booking_amount
FROM final.fct_flight_booking f
JOIN final.dim_customer c
    ON f.customer_key = c.customer_key
GROUP BY c.customer_country
ORDER BY total_flight_booking_amount DESC;
"
```

**Contoh pengecekan sampel data tabel final:**
```bash
docker compose exec dwh_db psql -U postgres -d pactravel-dwh -c "
SELECT * FROM final.fct_flight_booking LIMIT 10;
"
```
```bash
docker compose exec dwh_db psql -U postgres -d pactravel-dwh -c "
SELECT * FROM final.fct_hotel_booking LIMIT 10;
"
```
```bash
docker compose exec dwh_db psql -U postgres -d pactravel-dwh -c "
SELECT * FROM final.fct_daily_booking_summary ORDER BY date_key, service_type_key LIMIT 20;
"
```

---

### 7. Verifikasi terhadap Kebutuhan Bisnis
Hasil pemrosesan *pipeline* mengonfirmasi bahwa luaran akhir telah memenuhi spesifikasi kebutuhan analitik yang didefinisikan pada Step #1:
* **Jumlah Transaksi:** Dapat dianalisis menggunakan ukuran `booking_count` pada tabel fakta transaksi dan `total_bookings` pada tabel fakta *snapshot*.
* **Nilai Transaksi:** Dapat dianalisis menggunakan ukuran `booking_amount` dan `total_booking_amount`.
* **Tren Waktu:** Dapat dianalisis menggunakan kombinasi tabel `fct_daily_booking_summary` dan `dim_date`.
* **Kinerja Entitas (Maskapai & Hotel):** Dapat dianalisis melalui relasi `fct_flight_booking`, `fct_hotel_booking`, `dim_airline`, dan `dim_hotel`.
* **Analisis Geografis (Rute):** Didukung oleh penggunaan kolom *foreign key* `airport_src_key` dan `airport_dst_key` yang merujuk pada `dim_airport`.
* **Segmentasi Pengguna:** Didukung oleh relasi dengan `dim_customer`.

### 8. Kesimpulan
Implementasi proses *Extract, Load, Transform* (ELT) beroperasi sesuai dengan rancangan teknis. Ekstraksi data mentah dari sumber operasional menuju area DWH berjalan tanpa hambatan teknis. Pembangunan model *staging*, *snapshot*, *dimension*, dan *fact table* melalui dbt diselesaikan dengan seluruh *data quality tests* berstatus lulus. Dengan hasil ini, data operasional PacTravel telah terstruktur menjadi Data Warehouse berbasis *star schema* yang siap diintegrasikan untuk keperluan analitik dan pelaporan.