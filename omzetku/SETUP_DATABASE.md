# 📘 Setup Database PostgreSQL dengan Laravel

## 🎯 Arsitektur Aplikasi

```
Flutter App (Omzetku) ←→ Laravel API (Backend) ←→ PostgreSQL Database
     Port: Device              Port: 8000              Port: 5432
```

---

## ✅ Step 1: Instalasi PostgreSQL

### 1.1 Download dan Install PostgreSQL

- Download PostgreSQL dari: https://www.postgresql.org/download/windows/
- Jalankan installer dan ikuti wizard
- **Port default:** `5432`
- **Username default:** `postgres`
- **Set password:** Buat password untuk superuser (misal: `postgres`)

### 1.2 Akses PostgreSQL Database

**Via pgAdmin 4** (Sudah include saat install PostgreSQL):

- Buka **pgAdmin 4**
- Login dengan password yang dibuat saat install
- Expand **Servers** → **PostgreSQL**

**Via Command Line (psql):**

```bash
psql -U postgres
# Masukkan password saat diminta
```

---

## 🗄️ Step 2: Buat Database

### Via pgAdmin 4 (Recommended):

1. Buka pgAdmin 4
2. Right-click **Databases** → **Create** → **Database**
3. **Database name:** `omzetku`
4. **Owner:** `postgres`
5. **Encoding:** `UTF8`
6. Klik **Save**

### Via Command Line (psql):

```sql
CREATE DATABASE omzetku
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1;
```

Atau via terminal Windows:

```bash
psql -U postgres -c "CREATE DATABASE omzetku;"
```

---

## ⚙️ Step 3: Konfigurasi Laravel (.env)

Setelah Laravel terinstall di `d:\projects\omzetku-api`, edit file `.env`:

```env
APP_NAME="Omzetku API"
APP_URL=http://localhost:8000

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=omzetku
DB_USERNAME=postgres
DB_PASSWORD=your_postgres_password
```

**Catatan:** Ganti `your_postgres_password` dengan password PostgreSQL Anda

---

## 📊 Step 4: Struktur Database

### Tabel yang Akan Dibuat:

#### 1. **users** (Data Pengguna)

```sql
- id (Primary Key)
- nama_lengkap (VARCHAR)
- nama_usaha (VARCHAR)
- email (VARCHAR, UNIQUE)
- nomor_telepon (VARCHAR)
- password (VARCHAR, hashed)
- email_verified_at (TIMESTAMP)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### 2. **transaksi** (Data Transaksi Keuangan)

```sql
- id (Primary Key)
- user_id (Foreign Key → users.id)
- jenis (ENUM: 'pemasukan', 'pengeluaran')
- kategori (VARCHAR)
- jumlah (DECIMAL)
- tanggal (DATE)
- keterangan (TEXT)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### 3. **kategori** (Kategori Transaksi)

```sql
- id (Primary Key)
- user_id (Foreign Key → users.id)
- nama (VARCHAR)
- jenis (ENUM: 'pemasukan', 'pengeluaran')
- icon (VARCHAR)
- warna (VARCHAR)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

---

## 🔧 Step 5: Verifikasi Ekstensi PostgreSQL di PHP

Laravel membutuhkan ekstensi `pdo_pgsql` dan `pgsql` untuk koneksi PostgreSQL.

### Cek ekstensi sudah terinstall:

```bash
php -m | findstr pgsql
```

Jika output menampilkan `pdo_pgsql` dan `pgsql`, artinya sudah terinstall.

### Jika belum terinstall:

1. Buka `php.ini` (cari lokasi dengan `php --ini`)
2. Uncomment baris berikut (hapus `;` di awal):
   ```ini
   extension=pdo_pgsql
   extension=pgsql
   ```
3. Restart web server / terminal

---

## 🔧 Step 6: Jalankan Migration Laravel

```bash
cd d:\Data_Kuliah\Semester_5\PTI\Project\omzetku-api
php artisan migrate:fresh
```

Migration akan membuat semua tabel secara otomatis di database PostgreSQL `omzetku`.

---

## 🛠️ Step 7: Setup Laravel Sanctum (API Authentication)

Laravel Sanctum untuk handle login/register via API Token:

```bash
php artisan install:api
```

---

## 🚀 Step 8: Jalankan Laravel Server

```bash
cd d:\Data_Kuliah\Semester_5\PTI\Project\omzetku-api
php artisan serve
```

Server akan berjalan di: **http://localhost:8000**

---

## 📡 Step 9: API Endpoints yang Akan Dibuat

### Authentication:

- `POST /api/register` - Daftar akun baru
- `POST /api/login` - Login
- `POST /api/logout` - Logout
- `GET /api/user` - Get user info (protected)

### Transaksi:

- `GET /api/transaksi` - List semua transaksi
- `POST /api/transaksi` - Tambah transaksi baru
- `GET /api/transaksi/{id}` - Detail transaksi
- `PUT /api/transaksi/{id}` - Update transaksi
- `DELETE /api/transaksi/{id}` - Hapus transaksi

### Kategori:

- `GET /api/kategori` - List kategori
- `POST /api/kategori` - Tambah kategori
- `DELETE /api/kategori/{id}` - Hapus kategori

### Dashboard/Laporan:

- `GET /api/dashboard` - Summary keuangan
- `GET /api/laporan?from=2025-01-01&to=2025-12-31` - Laporan periode

---

## 🔐 Step 10: Testing API dengan Postman/Thunder Client

### Test Register:

```http
POST http://localhost:8000/api/register
Content-Type: application/json

{
  "nama_lengkap": "John Doe",
  "nama_usaha": "Toko ABC",
  "email": "john@example.com",
  "nomor_telepon": "08123456789",
  "password": "password123",
  "password_confirmation": "password123"
}
```

### Test Login:

```http
POST http://localhost:8000/api/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

Response akan berisi **token** yang digunakan untuk request berikutnya.

---

## 📱 Step 11: Integrasi Flutter dengan Laravel API

Di Flutter, kita akan menggunakan package `http` atau `dio`:

```dart
// pubspec.yaml
dependencies:
  http: ^1.1.0
```

```dart
// Login example
final response = await http.post(
  Uri.parse('http://localhost:8000/api/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': email,
    'password': password,
  }),
);
```

---

## 📝 Checklist Setup

- [ ] PostgreSQL sudah terinstall dan running
- [ ] PostgreSQL service running (port 5432)
- [ ] Database `omzetku` sudah dibuat
- [ ] Laravel project `omzetku-api` sudah dikonfigurasi
- [ ] File `.env` sudah dikonfigurasi untuk PostgreSQL
- [ ] Ekstensi PHP `pdo_pgsql` dan `pgsql` sudah aktif
- [ ] Migration sudah dijalankan (`php artisan migrate:fresh`)
- [ ] Laravel Sanctum sudah diinstall
- [ ] Laravel server running (`php artisan serve`)
- [ ] API endpoints sudah dibuat dan ditest
- [ ] Flutter siap integrasi dengan API

---

## 🆘 Troubleshooting

### Error: "SQLSTATE[08006] connection refused"

- Pastikan PostgreSQL service running
- Cek di Services Windows: **postgresql-x64-xx**
- Atau start manual: `pg_ctl -D "C:\Program Files\PostgreSQL\xx\data" start`

### Error: "SQLSTATE[08006] no password supplied"

- Pastikan `DB_PASSWORD` di `.env` sudah diisi
- Password harus sesuai dengan yang dibuat saat install PostgreSQL

### Error: "database omzetku does not exist"

- Buat database via pgAdmin 4 atau psql: `CREATE DATABASE omzetku;`

### Error: "could not find driver"

- Ekstensi PostgreSQL belum aktif di PHP
- Edit `php.ini`, uncomment: `extension=pdo_pgsql` dan `extension=pgsql`
- Restart terminal/server

### Error: "Connection refused" dari Flutter

- Pastikan Laravel server running: `php artisan serve`
- Cek URL API di Flutter app (http://localhost:8000)

### CORS Error dari Flutter

- Laravel 11 sudah built-in CORS support
- Config di `config/cors.php` jika perlu custom

---

## 🔄 Migrasi dari MySQL ke PostgreSQL

Jika sebelumnya pakai MySQL dan ingin migrasi:

1. **Export data MySQL** (via phpMyAdmin atau mysqldump)
2. **Convert SQL** (MySQL syntax → PostgreSQL syntax)
3. **Import ke PostgreSQL** (via pgAdmin atau psql)
4. **Update `.env`** (ganti connection ke pgsql)
5. **Test aplikasi** (pastikan semua query kompatibel)

**Catatan:** Beberapa syntax MySQL berbeda dengan PostgreSQL:

- AUTO_INCREMENT → SERIAL
- LIMIT offset, count → LIMIT count OFFSET offset
- Backtick \`table\` → Double quote "table"

---

## 📚 Next Steps

1. ✅ Setup database PostgreSQL (current step)
2. 🔄 Buat Laravel API endpoints (next)
3. 🔄 Integrasi Flutter dengan API
4. 🔄 Implementasi fitur UMKM (transaksi, laporan, dll)

---

**Created for:** Omzetku - Aplikasi Manajemen Keuangan UMKM  
**Tech Stack:** Flutter + Laravel + PostgreSQL  
**Database:** `omzetku` on PostgreSQL port 5432
