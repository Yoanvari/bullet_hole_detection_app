# Backend Auth — Bullet Detection

FastAPI + MySQL (XAMPP) untuk fitur **login** & **register** di `mobile_app` (Flutter).
Password disimpan sebagai hash **bcrypt**.

## Struktur

```
backend/
├── app/
│   ├── main.py          # entry FastAPI + CORS
│   ├── config.py        # baca .env
│   ├── database.py      # koneksi SQLAlchemy ke MySQL
│   ├── models.py        # model tabel users
│   ├── schemas.py       # validasi request/response (Pydantic)
│   ├── security.py      # hash & verify bcrypt
│   └── routers/
│       └── auth.py      # /api/auth/register & /api/auth/login
├── .env                 # konfigurasi DB (sudah diisi default XAMPP)
├── requirements.txt
└── run.py
```

## Cara menjalankan

1. Pastikan **MySQL & Apache** di XAMPP aktif, dan database `bullet_detection`
   sudah dibuat (jalankan `database/schema.sql`).

2. Buat virtual env & install dependency:

   ```bash
   cd backend
   python -m venv venv
   venv\Scripts\activate        # Windows
   pip install -r requirements.txt
   ```

3. Cek konfigurasi `.env` (default XAMPP: user `root`, password kosong).

4. Jalankan server:

   ```bash
   python run.py
   ```

   Server aktif di `http://localhost:8000`. Dokumentasi interaktif:
   `http://localhost:8000/docs`.

## Endpoint

### POST `/api/auth/register`
```json
{
  "email": "budi@example.com",
  "full_name": "Budi Santoso",
  "username": "budi",
  "password": "rahasia123",
  "confirm_password": "rahasia123"
}
```

### POST `/api/auth/login`
```json
{
  "username": "budi",
  "password": "rahasia123"
}
```

Response (sukses):
```json
{
  "success": true,
  "message": "Login berhasil",
  "user": { "id": 1, "username": "budi", "full_name": "Budi Santoso", "role": "shooter", ... }
}
```

## Catatan koneksi dari Flutter

- **Flutter Web (Chrome)** / desktop: `http://localhost:8000`
- **Emulator Android**: `http://10.0.2.2:8000`
- **HP fisik**: `http://<IP-komputer>:8000` (mis. `http://192.168.100.23:8000`)

Atur di `mobile_app/lib/services/api_service.dart` (konstanta `baseUrl`).
