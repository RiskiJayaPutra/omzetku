# OmzetKu - Aplikasi Manajemen Keuangan UMKM

Aplikasi mobile untuk mencatat dan mengelola transaksi keuangan UMKM dengan backend Laravel API.

## 📱 Fitur Aplikasi

### ✅ Sudah Terintegrasi dengan Database

- 🔐 **Autentikasi User** - Register, Login, Logout dengan Laravel Sanctum
- 💰 **Manajemen Transaksi** - Tambah, Lihat, Hapus transaksi (Pemasukan/Pengeluaran)
- 🔍 **Pencarian Riwayat** - Cari transaksi berdasarkan judul, kategori, atau catatan
- 📊 **Statistik Real-time** - Saldo, total pemasukan, dan pengeluaran
- 📅 **Filter Transaksi** - Tampilkan transaksi hari ini
- 🎨 **UI/UX Modern** - Desain clean dengan kategori berwarna

## 🏗️ Struktur Project

```
Project/
├── omzetku/                 # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart                    # Main app dengan integrasi API
│   │   ├── models/
│   │   │   └── transaction_model.dart   # Model dengan JSON serialization
│   │   ├── services/
│   │   │   └── api_service.dart         # HTTP client untuk Laravel API
│   │   └── screens/
│   │       ├── cari_riwayat_page.dart   # Halaman pencarian transaksi
│   │       ├── login_screen.dart        # Halaman login
│   │       └── register_screen.dart     # Halaman register
│   └── pubspec.yaml         # Dependencies: http, uuid, intl
│
├── omzetku-api/            # Laravel Backend API
│   ├── app/
│   │   ├── Models/
│   │   │   ├── User.php              # Model user dengan UMKM fields
│   │   │   └── Transaction.php       # Model transaksi
│   │   └── Http/Controllers/Api/
│   │       ├── AuthController.php           # Auth endpoints
│   │       └── TransactionController.php    # CRUD transaksi
│   ├── database/migrations/
│   │   ├── 2025_11_10_044532_add_umkm_fields_to_users_table.php
│   │   └── 2025_11_17_000000_create_transactions_table.php
│   └── routes/api.php       # API routes definition
│
├── INTEGRATION_GUIDE.md     # Panduan lengkap integrasi
├── QUICKSTART.md            # Quick start commands
└── API_CONFIG.md            # Konfigurasi API URL
```

## 🚀 Quick Start

### 1. Install Dependencies

**Flutter:**

```bash
cd omzetku
flutter pub get
```

**Laravel:**

```bash
cd omzetku-api
composer install
```

### 2. Setup Database

Edit `.env` di folder `omzetku-api`:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=omzetku_db
DB_USERNAME=root
DB_PASSWORD=
```

Jalankan migrations:

```bash
php artisan migrate
```

### 3. Konfigurasi API URL

Edit `omzetku/lib/services/api_service.dart` baris 8:

```dart
// Pilih sesuai platform testing:
static const String baseUrl = 'http://10.0.2.2:8000/api';  // Android Emulator
// static const String baseUrl = 'http://localhost:8000/api';  // iOS Simulator
// static const String baseUrl = 'http://192.168.1.X:8000/api';  // Physical Device
```

### 4. Jalankan Aplikasi

**Start Laravel Server:**

```bash
cd omzetku-api
php artisan serve
```

**Run Flutter App:**

```bash
cd omzetku
flutter run
```

## 📡 API Endpoints

### Authentication

| Method | Endpoint        | Description        | Auth |
| ------ | --------------- | ------------------ | ---- |
| POST   | `/api/register` | Register user baru | ❌   |
| POST   | `/api/login`    | Login user         | ❌   |
| POST   | `/api/logout`   | Logout user        | ✅   |
| GET    | `/api/user`     | Get user info      | ✅   |

### Transactions

| Method | Endpoint                             | Description         | Auth |
| ------ | ------------------------------------ | ------------------- | ---- |
| GET    | `/api/transactions`                  | Get semua transaksi | ✅   |
| POST   | `/api/transactions`                  | Tambah transaksi    | ✅   |
| GET    | `/api/transactions/{id}`             | Detail transaksi    | ✅   |
| PUT    | `/api/transactions/{id}`             | Update transaksi    | ✅   |
| DELETE | `/api/transactions/{id}`             | Hapus transaksi     | ✅   |
| GET    | `/api/transactions/search?q={query}` | Cari transaksi      | ✅   |
| GET    | `/api/transactions/statistics`       | Statistik transaksi | ✅   |

## 🗄️ Database Schema

### Table: users

- `id` - Primary Key
- `nama_lengkap` - Nama lengkap pemilik UMKM
- `nama_usaha` - Nama usaha/toko
- `nomor_telepon` - Nomor telepon
- `email` - Email (unique)
- `password` - Password (hashed)
- `timestamps`

### Table: transactions

- `id` - Primary Key
- `user_id` - Foreign Key ke users
- `title` - Judul transaksi
- `type` - Enum: 'Pemasukan' / 'Pengeluaran'
- `category` - Kategori transaksi
- `amount` - Nominal (decimal)
- `date_time` - Waktu transaksi
- `notes` - Catatan (nullable)
- `timestamps`

## 📦 Dependencies

### Flutter (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0 # HTTP client
  shared_preferences: ^2.2.2 # Local storage untuk token
  intl: ^0.19.0 # Format tanggal/angka
  uuid: ^4.3.3 # Generate UUID
```

### Laravel (composer.json)

```json
{
  "require": {
    "laravel/framework": "^11.0",
    "laravel/sanctum": "^4.0"
  }
}
```

## 🔧 Troubleshooting

### Connection Refused

✅ Pastikan Laravel server berjalan: `php artisan serve`  
✅ Cek URL di `api_service.dart` sudah benar  
✅ Untuk Android Emulator gunakan `10.0.2.2` bukan `localhost`

### 401 Unauthorized

✅ User belum login atau token expired  
✅ Login kembali untuk generate token baru

### Cannot find package

✅ Jalankan `flutter pub get`  
✅ Jalankan `composer install` di Laravel

### CORS Error

Tambahkan di `config/cors.php`:

```php
'paths' => ['api/*'],
'allowed_origins' => ['*'],
'allowed_methods' => ['*'],
```

## 📱 Testing

### Test dengan Flutter App

1. Buka aplikasi
2. Register akun baru
3. Login dengan akun tersebut
4. Tambah transaksi baru
5. Cari transaksi di halaman Riwayat

### Test dengan API Client (Postman/Thunder Client)

**Register:**

```bash
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

**Add Transaction:**

```bash
POST http://localhost:8000/api/transactions
Authorization: Bearer {token_from_login}
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

## 🎯 Roadmap

### ✅ Completed

- [x] User authentication dengan Sanctum
- [x] CRUD transaksi terintegrasi database
- [x] Pencarian transaksi
- [x] Statistik real-time
- [x] UI responsive dan modern

### 🚧 Future Development

- [ ] Edit transaksi
- [ ] Export laporan (PDF/Excel)
- [ ] Grafik visualisasi data
- [ ] Notifikasi pengingat
- [ ] Multi-currency support
- [ ] Backup & restore data
- [ ] Offline mode dengan sync

## 📄 License

This project is for educational purposes.

## 👥 Team

Developed for PTI Project - Semester 5

## 📞 Support

For questions and support, please refer to:

- `INTEGRATION_GUIDE.md` - Full integration guide
- `QUICKSTART.md` - Quick start commands
- `API_CONFIG.md` - API configuration details

---

**Happy Coding! 🚀**
