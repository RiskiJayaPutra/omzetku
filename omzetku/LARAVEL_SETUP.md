# 🚀 Setup Laravel API untuk Omzetku - Panduan Lengkap

## 📋 Checklist Setup

- [ ] 1. Laravel terinstall
- [ ] 2. Database MySQL dibuat di Laragon
- [ ] 3. Konfigurasi .env
- [ ] 4. Install Sanctum
- [ ] 5. Buat Migration
- [ ] 6. Buat Model & Controller
- [ ] 7. Setup Routes
- [ ] 8. Test API
- [ ] 9. Integrasi Flutter

---

## 🗄️ Step 1: Buat Database di Laragon

1. Pastikan **Laragon** running
2. Buka **HeidiSQL** (klik kanan Laragon → Database → HeidiSQL)
3. Klik kanan → **Create new → Database**
4. Nama: `omzetku_db`
5. Charset: `utf8mb4_unicode_ci`
6. Klik **OK**

---

## ⚙️ Step 2: Konfigurasi .env

Buka file `d:\projects\omzetku-api\.env` dan edit:

```env
APP_NAME="Omzetku API"
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=omzetku_db
DB_USERNAME=root
DB_PASSWORD=
```

**Note:** Jika MySQL Laragon pakai password, isi `DB_PASSWORD`

---

## 🔑 Step 3: Install Laravel Sanctum

Jalankan di terminal:

```bash
cd d:\projects\omzetku-api
php artisan install:api
```

Ketik `yes` saat diminta untuk run migration.

---

## 📊 Step 4: Struktur Database

### Tabel Users (akan kita modifikasi)

Tambah field:

- `nama_lengkap` (VARCHAR)
- `nama_usaha` (VARCHAR)
- `nomor_telepon` (VARCHAR)

### Command untuk membuat migration:

```bash
php artisan make:migration add_umkm_fields_to_users_table --table=users
```

---

## 📝 File-File yang Akan Dibuat

Setelah Laravel selesai install, kita akan membuat:

1. **Migration** - Untuk tambah field UMKM di tabel users
2. **Model User** - Update model User dengan field baru
3. **AuthController** - Handle login, register, logout
4. **API Routes** - Endpoint untuk authentication

---

## 📡 API Endpoints yang Akan Tersedia

### Public (tanpa authentication):

- `POST /api/register` - Daftar akun baru
- `POST /api/login` - Login

### Protected (butuh token):

- `GET /api/user` - Get user info
- `POST /api/logout` - Logout

---

## 🧪 Contoh Request/Response

### Register

```json
POST http://localhost:8000/api/register

{
  "nama_lengkap": "John Doe",
  "nama_usaha": "Toko ABC",
  "email": "john@example.com",
  "nomor_telepon": "08123456789",
  "password": "password123",
  "password_confirmation": "password123"
}

Response:
{
  "success": true,
  "message": "Registrasi berhasil",
  "data": {
    "user": {...},
    "access_token": "1|xxx...",
    "token_type": "Bearer"
  }
}
```

### Login

```json
POST http://localhost:8000/api/login

{
  "email": "john@example.com",
  "password": "password123"
}

Response:
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "user": {...},
    "access_token": "2|yyy...",
    "token_type": "Bearer"
  }
}
```

---

## 🎯 Setelah Laravel Selesai Install

Saya akan:

1. ✅ Install Sanctum
2. ✅ Buat migration untuk field UMKM
3. ✅ Buat AuthController
4. ✅ Setup routes
5. ✅ Jalankan server
6. ✅ Test API
7. ✅ Integrasi dengan Flutter

---

**Status:** ⏳ Menunggu Laravel selesai install...
