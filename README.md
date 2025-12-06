# Omzetku - Aplikasi Manajemen Keuangan UMKM

Aplikasi manajemen keuangan berbasis Flutter dan Laravel yang dirancang khusus untuk membantu pelaku UMKM dalam mengelola transaksi, menganalisis keuangan, dan membuat keputusan bisnis yang lebih baik.

## Fitur Utama

### Manajemen Transaksi
- Pencatatan transaksi pemasukan dan pengeluaran dengan kategori lengkap
- Sistem produk terintegrasi dengan perhitungan otomatis berdasarkan quantity
- Dukungan untuk transaksi produk fisik dan jasa
- Edit dan hapus transaksi dengan konfirmasi keamanan
- Filter dan pencarian transaksi berdasarkan tanggal, kategori, dan tipe

### Manajemen Produk
- Database produk dengan harga dan tipe (fisik/jasa)
- Perhitungan otomatis nominal transaksi: harga × quantity
- Tracking quantity produk yang terjual
- Auto-fill informasi produk saat membuat transaksi

### Visualisasi Data
- Dashboard dengan ringkasan keuangan real-time
- Grafik pemasukan dan pengeluaran
- Analisis tren keuangan per periode
- Perhitungan otomatis saldo, total pemasukan, dan pengeluaran

### Manajemen Profil
- Profil UMKM dengan informasi lengkap
- Upload dan update foto profil
- Data UMKM: nama, alamat, deskripsi, dan jenis usaha
- Edit profil dengan validasi form

## Teknologi

### Frontend (Flutter)
- **Framework**: Flutter 3.24.5
- **Language**: Dart 3.5.4
- **State Management**: StatefulWidget
- **HTTP Client**: http package
- **Charts**: fl_chart
- **Authentication**: Firebase Auth & Laravel Sanctum
- **Image Handling**: image_picker, http_parser

### Backend (Laravel)
- **Framework**: Laravel 12.x
- **Language**: PHP 8.2+
- **Database**: PostgreSQL 14+
- **Authentication**: Laravel Sanctum
- **API**: RESTful API
- **File Storage**: Local storage dengan CORS support

### Database Schema
- **users**: Data pengguna dan informasi UMKM
- **transactions**: Transaksi dengan relasi ke produk
- **products**: Database produk dengan harga dan tipe
- **personal_access_tokens**: Token autentikasi Sanctum

## Instalasi

### Prasyarat
```
- Flutter SDK 3.24.5 atau lebih tinggi
- Dart SDK 3.5.4 atau lebih tinggi
- PHP 8.2 atau lebih tinggi
- Composer 2.x
- PostgreSQL 14 atau lebih tinggi
- Git
```

### Backend Setup

1. Clone repository
```bash
git clone https://github.com/RiskiJayaPutra/omzetku.git
cd omzetku/omzetku-api
```

2. Install dependencies
```bash
composer install
```

3. Setup environment
```bash
cp .env.example .env
```

4. Konfigurasi database di `.env`
```env
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=omzetku
DB_USERNAME=postgres
DB_PASSWORD=your_password
```

5. Generate key dan jalankan migrasi
```bash
php artisan key:generate
php artisan migrate
```

6. Jalankan server
```bash
php artisan serve
```

Backend akan berjalan di `http://localhost:8000`

### Frontend Setup

1. Masuk ke direktori Flutter
```bash
cd ../omzetku
```

2. Install dependencies
```bash
flutter pub get
```

3. Konfigurasi API endpoint di `lib/services/api_service.dart`
```dart
static const String baseUrl = 'http://localhost:8000/api';
```

4. Jalankan aplikasi
```bash
# Untuk Web
flutter run -d chrome

# Untuk Android
flutter run

# Untuk iOS
flutter run -d ios
```

## API Endpoints

### Authentication
- `POST /api/register` - Registrasi pengguna baru
- `POST /api/login` - Login pengguna
- `POST /api/logout` - Logout pengguna
- `GET /api/user` - Get data pengguna yang login
- `POST /api/user/update` - Update profil pengguna

### Transactions
- `GET /api/transactions` - List semua transaksi
- `POST /api/transactions` - Buat transaksi baru
- `GET /api/transactions/{id}` - Detail transaksi
- `PUT /api/transactions/{id}` - Update transaksi
- `DELETE /api/transactions/{id}` - Hapus transaksi
- `GET /api/transactions/search?q=query` - Cari transaksi
- `GET /api/transactions/statistics` - Statistik transaksi

### Products
- `GET /api/products` - List semua produk
- `POST /api/products` - Buat produk baru
- `GET /api/products/{id}` - Detail produk
- `PUT /api/products/{id}` - Update produk
- `DELETE /api/products/{id}` - Hapus produk

## Struktur Proyek

```
omzetku/
├── omzetku/                          # Flutter Frontend
│   ├── lib/
│   │   ├── models/                   # Data models
│   │   ├── screens/                  # UI screens
│   │   ├── services/                 # API services
│   │   ├── utils/                    # Utilities & helpers
│   │   ├── widgets/                  # Reusable widgets
│   │   └── main.dart                 # Entry point
│   ├── assets/                       # Images & assets
│   └── pubspec.yaml                  # Flutter dependencies
│
└── omzetku-api/                      # Laravel Backend
    ├── app/
    │   ├── Http/Controllers/         # API controllers
    │   └── Models/                   # Eloquent models
    ├── database/
    │   └── migrations/               # Database migrations
    ├── routes/
    │   └── api.php                   # API routes
    └── public/
        └── uploads/                  # User uploads
```

## Penggunaan

### Registrasi & Login
1. Buka aplikasi dan klik "Daftar"
2. Isi form registrasi dengan data UMKM
3. Login menggunakan email dan password

### Menambah Transaksi
1. Klik tombol "+" di bottom navigation
2. Pilih tipe: Pemasukan atau Pengeluaran
3. Pilih kategori transaksi
4. Untuk transaksi produk:
   - Pilih kategori "Penjualan Produk" atau "Penjualan Jasa"
   - Pilih produk dari dropdown
   - Input quantity (jumlah)
   - Nominal akan dihitung otomatis
5. Klik "Simpan Transaksi"

### Mengelola Produk
1. Buka menu drawer (kiri atas)
2. Pilih "Manajemen Produk"
3. Tambah produk baru dengan nama, harga, dan tipe
4. Edit atau hapus produk yang sudah ada

### Melihat Statistik
1. Dashboard menampilkan ringkasan keuangan
2. Tap "Grafik" untuk visualisasi detail
3. Filter berdasarkan periode waktu

## Testing

### Backend Testing
```bash
cd omzetku-api
php artisan test
```

### Frontend Testing
```bash
cd omzetku
flutter test
```

## Deployment

### Backend (Laravel)
1. Setup server dengan PHP 8.2+ dan PostgreSQL
2. Clone repository dan install dependencies
3. Konfigurasi `.env` untuk production
4. Jalankan migrasi: `php artisan migrate --force`
5. Setup web server (Nginx/Apache)
6. Konfigurasi CORS dan file permissions

### Frontend (Flutter)
```bash
# Build untuk Web
flutter build web

# Build untuk Android
flutter build apk --release

# Build untuk iOS
flutter build ios --release
```

## Kontribusi

Kontribusi sangat diterima. Untuk perubahan besar, harap buka issue terlebih dahulu untuk mendiskusikan perubahan yang diinginkan.

1. Fork repository
2. Buat branch fitur (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

## Lisensi

Proyek ini dilisensikan di bawah MIT License.

## Kontak

Riski Jaya Putra - [@RiskiJayaPutra](https://github.com/RiskiJayaPutra)

Repository: [https://github.com/RiskiJayaPutra/omzetku](https://github.com/RiskiJayaPutra/omzetku)

## Changelog

### Version 1.0.0 (2025-12-06)
- Initial release
- Manajemen transaksi dengan kategori lengkap
- Integrasi produk dengan perhitungan otomatis
- Dashboard dan visualisasi data
- Manajemen profil UMKM
- Upload foto profil
- Filter dan pencarian transaksi
- Responsive design untuk mobile dan web
