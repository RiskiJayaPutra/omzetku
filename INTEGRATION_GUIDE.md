# Setup Guide - Integrasi Database OmzetKu

## Langkah 1: Install Dependencies Flutter

Jalankan perintah berikut di folder `omzetku`:

```bash
cd omzetku
flutter pub get
```

## Langkah 2: Setup Laravel Database

1. Masuk ke folder `omzetku-api`:

```bash
cd omzetku-api
```

2. Jalankan migration untuk membuat tabel transactions:

```bash
php artisan migrate
```

3. Pastikan Laravel server berjalan:

```bash
php artisan serve
```

Server akan berjalan di `http://localhost:8000`

## Langkah 3: Konfigurasi API URL

Edit file `lib/services/api_service.dart` dan sesuaikan `baseUrl`:

- **Android Emulator**: `http://10.0.2.2:8000/api`
- **iOS Simulator**: `http://localhost:8000/api`
- **Real Device**: `http://[YOUR_IP]:8000/api` (contoh: `http://192.168.1.5:8000/api`)

Untuk menemukan IP komputer Anda:

- Windows: `ipconfig` (cari IPv4 Address)
- Mac/Linux: `ifconfig` atau `ip addr`

## Langkah 4: Setup Assets (Opsional)

Buat folder untuk logo:

```bash
mkdir -p omzetku/assets/images
```

Letakkan file logo `omzetku.png` di folder tersebut.

## Langkah 5: Jalankan Aplikasi Flutter

```bash
cd omzetku
flutter run
```

## Struktur Database

Tabel `transactions`:

- id (primary key)
- user_id (foreign key ke users)
- title (string)
- type (enum: 'Pemasukan' / 'Pengeluaran')
- category (string)
- amount (decimal)
- date_time (datetime)
- notes (text, nullable)
- timestamps

## API Endpoints

### Auth

- POST `/api/register` - Registrasi user baru
- POST `/api/login` - Login user
- POST `/api/logout` - Logout user (protected)
- GET `/api/user` - Get user info (protected)

### Transactions (semua protected)

- GET `/api/transactions` - Get semua transaksi user
- POST `/api/transactions` - Tambah transaksi baru
- GET `/api/transactions/{id}` - Get detail transaksi
- PUT `/api/transactions/{id}` - Update transaksi
- DELETE `/api/transactions/{id}` - Hapus transaksi
- GET `/api/transactions/search?q={query}` - Cari transaksi
- GET `/api/transactions/statistics` - Get statistik transaksi

## Troubleshooting

### Error: Connection Refused

- Pastikan Laravel server berjalan (`php artisan serve`)
- Cek URL API di `api_service.dart` sudah benar
- Pastikan tidak ada firewall yang memblokir koneksi

### Error: 401 Unauthorized

- User belum login atau token expired
- Login kembali untuk mendapatkan token baru

### Error: Cannot find package

- Jalankan `flutter pub get` untuk install dependencies
- Jalankan `composer install` di folder Laravel

### Error: CORS

Tambahkan konfigurasi CORS di Laravel (`config/cors.php`):

```php
'paths' => ['api/*'],
'allowed_origins' => ['*'],
'allowed_methods' => ['*'],
'allowed_headers' => ['*'],
```

## Fitur yang Sudah Terintegrasi

✅ Login & Register dengan Laravel API
✅ Tambah, Hapus, Lihat transaksi
✅ Pencarian riwayat transaksi
✅ Sinkronisasi data dengan database
✅ Statistik pemasukan & pengeluaran real-time
✅ Filter transaksi hari ini
✅ Protected routes dengan Sanctum token

## Testing API dengan Postman/Thunder Client

### 1. Register

```
POST http://localhost:8000/api/register
Content-Type: application/json

{
  "nama_lengkap": "John Doe",
  "nama_usaha": "Warung Makan",
  "nomor_telepon": "08123456789",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

### 2. Login

```
POST http://localhost:8000/api/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

Response akan berisi token, simpan untuk request selanjutnya.

### 3. Tambah Transaksi

```
POST http://localhost:8000/api/transactions
Authorization: Bearer {your_token}
Content-Type: application/json

{
  "title": "Belanja Mingguan",
  "type": "Pengeluaran",
  "category": "Belanja",
  "amount": 50000,
  "date_time": "2025-11-17T10:00:00",
  "notes": "Ayam, sayur, dan lainnya"
}
```

## Next Steps

1. **Testing**: Test semua fitur untuk memastikan integrasi berjalan lancar
2. **UI/UX**: Sesuaikan tampilan sesuai kebutuhan
3. **Validasi**: Tambahkan validasi form yang lebih lengkap
4. **Error Handling**: Improve error messages untuk user
5. **Loading States**: Tambahkan loading indicators yang lebih baik
6. **Offline Mode**: Implementasi cache lokal untuk mode offline

---

**Catatan**: Pastikan semua environment variable di `.env` Laravel sudah dikonfigurasi dengan benar, terutama database connection.
