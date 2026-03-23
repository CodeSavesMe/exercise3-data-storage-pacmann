Tentu, ini draf yang sudah dirapikan dengan gaya dokumentasi yang lebih terstruktur, profesional, dan sangat cocok untuk dijadikan bagian dari `README` GitHub ala *cohort* DataTalks.Club. 

Aku menggunakan kombinasi *bullet points*, *bold text* untuk penekanan, dan tabel yang lebih rapi agar mudah dipindai oleh *reviewer*.

***

## Step 1: Requirements Gathering

### 1. Description
Sistem sumber (`pactravel`) beroperasi menggunakan database **PostgreSQL** dengan skema berbasis **OLTP** (Online Transaction Processing). Database ini dirancang untuk mencatat data operasional *booking* perjalanan harian secara *real-time*.

**Struktur Skema Sumber:**
* **Tabel Master (Dimensi Potensial):** `customers`, `airlines`, `aircrafts`, `airports`, `hotels`
* **Tabel Transaksi (Fakta Potensial):** `flight_bookings`, `hotel_bookings`

**Detail Tabel Transaksi Utama:**

| Tabel | Kolom | Deskripsi |
| :--- | :--- | :--- |
| **`flight_bookings`** | `customer_id`, `flight_number`, `airline_id`, `aircraft_id` | Identitas pelanggan dan detail operasional penerbangan. |
| | `airport_src`, `airport_dst` | Rute bandara keberangkatan dan tujuan. |
| | `departure_date`, `departure_time`, `flight_duration` | Metrik waktu dan durasi perjalanan. |
| | `travel_class`, `seat_number`, `price` | Detail kelas layanan dan nilai transaksi *booking*. |
| **`hotel_bookings`** | `customer_id`, `hotel_id` | Identitas pelanggan dan lokasi penginapan. |
| | `check_in_date`, `check_out_date` | Periode waktu penginapan. |
| | `price`, `breakfast_included` | Nilai transaksi dan fasilitas tambahan. |

**Proses Bisnis Utama & Kebutuhan Analitik:**
Fokus utama dari *dataset* ini mencakup layanan **Booking Penerbangan** dan **Booking Hotel**. Analitik dasar yang diharapkan oleh *stakeholder* meliputi:
* Total volume dan nilai transaksi *booking*.
* Analisis tren performa maskapai dan hotel.
* Analisis popularitas rute penerbangan.
* *Profiling* dan segmentasi perilaku pelanggan.

---

### 2. Problem
Melakukan kueri analitik secara langsung pada sumber data operasional (OLTP) saat ini menimbulkan beberapa hambatan teknis dan bisnis:

* **Skema Berorientasi Transaksi (Ter-normalisasi):** Skema saat ini dioptimalkan untuk proses *insert/update* harian yang cepat, bukan untuk agregasi pembacaan data historis dalam jumlah besar.
* **Silo Data Transaksi:** Data *booking* penerbangan dan hotel terpisah di tabel yang berbeda. Hal ini menyulitkan analisis *cross-selling* atau pemahaman perjalanan pengguna secara holistik.
* **Query Analitik yang Terlalu Kompleks:** Menghasilkan laporan sederhana mensyaratkan banyak operasi `JOIN` ke berbagai tabel master.
* **Beban Komputasi Tinggi:** Analisis pada `flight_bookings` membutuhkan setidaknya lima operasi `JOIN` ke entitas lain (pelanggan, maskapai, pesawat, dan dua entri bandara). Ini menyebabkan proses *reporting* berjalan lambat dan membebani database operasional.
* **Keterbatasan Konteks Data:** Sumber saat ini belum mencakup *state* penting seperti status pembayaran, pembatalan (*cancellation*), atau *trip header* pemersatu, sehingga membatasi visibilitas terhadap *lifecycle* pengguna secara *end-to-end*.

---

### 3. Solution
Untuk menjawab tantangan di atas, solusi yang diusulkan adalah merancang dan membangun **Data Warehouse (DWH)** menggunakan pendekatan **Dimensional Modeling** (Star Schema). 

**Arsitektur & Alur Transformasi (ELT):**
1.  **Extract & Load (EL):** Mengekstrak data mentah dari PostgreSQL OLTP dan memuatnya ke dalam **Schema Staging** di Data Warehouse.
2.  **Transform (T):** Mentransformasi data mentah dari *staging* menjadi tabel **Fact** dan **Dimension** yang terdenormalisasi di skema analitik akhir.

**Target Output Analitik (Data Marts):**
Pembangunan DWH ini akan memfasilitasi pembuatan *dashboard* dengan metrik siap pakai, seperti:
* Tren volume dan nilai *booking* harian.
* Tabel agregasi performa per entitas (Maskapai & Hotel).
* Tabel analisis rute penerbangan dan demografi pelanggan.

**Tech Stack Data Pipeline:**
* **Python:** Untuk proses *Extract* dan *Load* dari sumber ke *staging*.
* **Luigi:** Sebagai *Orchestrator* untuk mengatur urutan *task*, penjadwalan (*scheduling*), dan penanganan *alerting*.
* **dbt (Data Build Tool):** Untuk menjalankan transformasi data (pembentukan model dimensi) di dalam area DWH dengan penerapan praktik *software engineering* (pengujian dan dokumentasi).

**Hasil Akhir (Impact):**
Query analitik akan menjadi jauh lebih ringkas (*fewer joins*), performa baca akan meningkat drastis, metrik bisnis menjadi terstandardisasi (*Single Source of Truth*), dan keseluruhan *pipeline* akan berjalan secara otomatis dan *reproducible*.
