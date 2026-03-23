
## Step #3 — Data Pipeline Implementation

### 1. Overview
Pada tahap ini, *workflow* **ELT (Extract, Load, Transform)** diimplementasikan untuk memindahkan data dari sistem sumber PacTravel ke Data Warehouse (DWH) dan membangun tabel analitik berdasarkan *Dimensional Model* (Star Schema) yang telah dirancang pada Step #2.

**Tech Stack yang Digunakan:**
* **PostgreSQL:** Bertindak sebagai *source database* (OLTP) sekaligus target Data Warehouse.
* **Python:** Menangani proses *Extract* data mentah dari sumber dan *Load* ke DWH.
* **dbt (Data Build Tool):** Menjalankan transformasi data dari *raw/staging layer* menjadi *final data mart*.
* **DBeaver:** Digunakan sebagai *database client* utama untuk inspeksi data sumber, validasi *raw load*, dan pengecekan hasil transformasi final.

---

### 2. Pipeline Architecture & Tool Responsibilities
Arsitektur *pipeline* dibagi menjadi tiga *layer* utama di dalam ekosistem PostgreSQL:

**1. Source Layer (`public` schema pada Source DB)**
Menyimpan tabel operasional operasional asli: `customers`, `airlines`, `aircrafts`, `airports`, `hotel`, `flight_bookings`, `hotel_bookings`.

**2. Raw / Staging Layer (`pactravel` & `staging` schema pada DWH DB)**
* **Python** bertanggung jawab mengamankan koneksi, mengekstrak data dari sumber, dan memuat salinan penuh (*full refresh*) ke skema `pactravel` di DWH. 
* **dbt** kemudian membaca *raw data* ini untuk membangun *staging views* di skema `staging`, melakukan pembersihan ringan (*casting* tipe data, *trimming* string, penanganan *null*).

**3. Final Layer (`final` & `snapshots` schema pada DWH DB)**
* **dbt** mentransformasi data *staging* menjadi tabel *Dimension* dan *Fact* (*star schema*).
* **dbt Snapshots** digunakan untuk merekam histori perubahan dimensi (SCD Type 2) pada skema terpisah.

---

### 3. ELT Workflow Execution

#### A. Extract & Load (Python)
Proses ekstraksi menggunakan *script* Python yang membaca konfigurasi kredensial dari file `.env` (memuat detail *host, port, user, password* untuk *Source* dan *DWH*).

**Mekanisme Load (Full Refresh):**
1. Memastikan skema dan tabel *raw target* tersedia di DWH.
2. Melakukan operasi `TRUNCATE` pada tabel target untuk mengosongkan data lama.
3. Mengekstrak data operasional dan melakukan `APPEND` ke tabel *raw*.
4. **Hasil Ekstraksi (Row Counts):**
   * `customers`: 1,000 baris
   * `airlines`: 1,251 baris
   * `aircrafts`: 246 baris
   * `airports`: 105 baris
   * `hotel`: 1,470 baris
   * `flight_bookings`: 8,190 baris
   * `hotel_bookings`: 217 baris

#### B. Transform (dbt)
Transformasi dbt dikonfigurasi dengan `models/sources.yml` sebagai titik masuk, lalu dieksekusi dalam tiga fase:
1. **Staging Models:** Membuat *view* ringan yang menormalisasi nama kolom dan tipe data dari *raw tables*.
2. **Snapshots (SCD Type 2):** Menjalankan `snap_customer` dan `snap_hotel` menggunakan `strategy='check'` pada kolom-kolom yang relevan untuk merekam histori perubahan tanpa bergantung pada kolom *audit* dari *source*.
3. **Mart Models:** Membangun *dimension* dan *fact tables*. Khusus untuk tabel fakta, relasi ke dimensi historis (Type 2) ditangani menggunakan *as-of date join* agar transaksi merujuk pada versi atribut dimensi yang benar di waktu tersebut.

---

### 4. Scheduling & Orchestration
Pipeline dirancang untuk berjalan secara periodik (misalnya, harian). Untuk implementasi lokal ini, eksekusi dijadwalkan menggunakan *task runner* atau pengeksekusian manual secara berurutan.

**Urutan Eksekusi (*Run Order*):**
```bash
# 1. Jalankan proses Extract & Load
uv run python -m pactravel_dwh.load_raw_to_dwh

# 2. Bangun layer Staging
dbt run --select models/staging

# 3. Tangkap histori perubahan dimensi (SCD2)
dbt snapshot

# 4. Bangun final Data Marts
dbt run --select models/marts

# 5. Jalankan Data Quality Tests
dbt test
```

---

### 5. Monitoring, Alerting & Logging
Untuk memastikan keandalan *pipeline*, sistem menerapkan *monitoring* di mana seluruh log eksekusi tersimpan secara persisten.

* **Log Penyimpanan:** Memastikan seluruh *log file* dari Python (`summary JSON`) dan dbt (`dbt.log`) tersimpan utuh sebagai jejak audit jika terjadi kegagalan (misal: koneksi terputus atau target tabel tidak ditemukan).
* **Alerting Sederhana:** Mengandalkan *console output* dan status *exit code* dari proses penjadwalan.

---

### 6. Data Quality Checks
Validasi data diimplementasikan secara ketat menggunakan dbt tests:

* **Generic Tests:** Memastikan integritas dasar seperti `not_null`, `unique`, kecocokan `relationships` (*referential integrity*), dan `accepted_values`.
* **Custom Singular Tests:** SQL spesifik yang dirancang untuk menguji *business logic*:
  * Memastikan *grain fact table* unik (`test_fct_flight_booking_unique_grain.sql`, dll).
  * Memastikan rentang waktu histori SCD Type 2 tidak tumpang tindih (`test_dim_customer_no_overlapping_ranges.sql`).
  * Memvalidasi kebenaran nilai turunan, seperti jumlah malam menginap (`test_fct_hotel_booking_valid_stay_nights.sql`).

#### dbt Execution Results
Keseluruhan *pipeline* dan pengujian telah berhasil dieksekusi dengan *summary* keluaran:
* **Models:** 17
* **Snapshots:** 2
* **Tests:** 110 (berasal dari 7 *sources*)
* **Status:** **PASS = 129 | WARN = 0 | ERROR = 0**

Hasil ini memvalidasi bahwa data berhasil diekstrak, dimodelkan ulang menjadi *Star Schema*, diuji secara menyeluruh, dan siap dihubungkan ke *BI Tools* untuk *reporting*.
