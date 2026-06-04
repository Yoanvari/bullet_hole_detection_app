# Database — Bullet Hole Detection System

Dokumen ini menjelaskan struktur database (`schema.sql`) dan **kemungkinan fitur** yang bisa dibangun di **desktop_app** dan **mobile_app** berdasarkan tabel-tabel yang tersedia.

## Ringkasan Skema

| Tabel | Fungsi |
|-------|--------|
| `users` | Akun penembak (sipenembak), instruktur, dan admin. |
| `devices` | Stasiun/komputer desktop yang menjalankan deteksi (multi-lane). |
| `sessions` | Sesi latihan menembak per penembak + data kalibrasi target. |
| `shots` | Tiap lubang peluru terdeteksi beserta skor (0–10) dan gambar. |
| `v_session_summary` | View ringkasan: total tembakan, total skor, rata-rata per sesi. |

Relasi inti: `users (1) → (N) sessions (1) → (N) shots`. Sebuah sesi opsional terhubung ke `instructor_id` dan `device_id`.

---

## desktop_app — Deteksi & Penilaian

Desktop app adalah sisi **operator**: menangkap video, mendeteksi lubang peluru (YOLO), menghitung skor, dan menulis data ke database.

**Manajemen perangkat & sesi**
- Mendaftarkan stasiun deteksi ke tabel `devices` (kode lane, IP, lokasi) sehingga beberapa komputer bisa dibedakan.
- Memulai sesi latihan baru (`sessions`): memilih penembak (`shooter_id`), pengawas (`instructor_id`), jarak target, lalu menandai `status = 'ongoing'`.
- Menyimpan hasil kalibrasi target (warping/elips) ke `is_calibrated`, `target_center_x/y`, dan `target_radius` agar penilaian konsisten.
- Menutup sesi dengan mengisi `ended_at` dan `status = 'completed'` (atau `'cancelled'`).

**Deteksi & scoring**
- Setiap lubang yang terdeteksi (setelah debounce) ditulis sebagai baris di `shots`: nomor urut (`shot_number`), skor 0–10 (`calculate_score_circle`), serta koordinat `hole_x`, `hole_y`, `distance_from_center`, dan `confidence` YOLO.
- Menyimpan foto tembakan ke disk lalu mencatat `image_filename`, `image_path` (lokal), dan `image_url` (yang nantinya dibaca mobile).
- Karena ada constraint `CHECK (score BETWEEN 0 AND 10)`, data skor invalid otomatis ditolak.

**Analitik operator**
- Melihat rekap langsung lewat `v_session_summary` (total & rata-rata skor) tanpa menghitung manual.
- Membandingkan performa antar penembak atau antar stasiun (`device_id`).
- Mengelola akun penembak/instruktur di `users` (tambah, nonaktifkan via `is_active`, atur `role`).

---

## mobile_app — Penembak (Sipenembak)

Mobile app adalah sisi **penembak**: terutama membaca data, login, melihat live, dan riwayat.

**Autentikasi**
- Login memakai `username` + `password_hash` di tabel `users` (role `shooter`).
- Mencatat `last_login_at` dan menampilkan profil (`full_name`, `rank_title`, `avatar_path`).

**Tampilan live**
- Menampilkan tembakan terbaru dari sesi yang sedang `ongoing` (query `shots` terbaru per `session_id`).
- Memuat gambar tembakan via `image_url` dan menampilkan skornya secara real-time.

**Riwayat latihan**
- Menampilkan daftar sesi milik penembak (`sessions` difilter `shooter_id`), diurutkan `started_at`.
- Setiap sesi menunjukkan total tembakan & total skor langsung dari `v_session_summary` (sesuai `getter totalShots`/`totalScore` di `SessionModel`).
- Membuka detail sesi untuk melihat seluruh `shots`: gambar, nomor urut, dan skor masing-masing.

**Statistik pribadi**
- Menghitung rata-rata skor, skor tertinggi, dan tren antar sesi dari data `shots`/`v_session_summary`.
- Memungkinkan grafik perkembangan dari waktu ke waktu memakai `captured_at` dan `started_at`.

---

## Alur Data Singkat

```
desktop_app  ──(deteksi + skor)──►  shots / sessions  ◄──(baca live & riwayat)──  mobile_app
        │                                  ▲
        └────── devices / users ───────────┘
```

1. Operator mulai sesi di desktop → baris baru di `sessions`.
2. Tiap lubang terdeteksi → baris baru di `shots` + foto disimpan.
3. Penembak login di mobile → membaca `shots` (live) dan `sessions` (riwayat) miliknya.

---

## Cara Memuat Skema

```bash
mysql -u root -p < schema.sql
```

> Catatan: kolom `password_hash` pada data contoh masih berupa placeholder. Ganti dengan hash asli (bcrypt/argon2) sebelum produksi.
