# Quick Start Commands

## Setup Database & Run

### 1. Install Flutter Dependencies

```bash
cd omzetku
flutter pub get
```

### 2. Setup Laravel & Run Migrations

```bash
cd omzetku-api
composer install
php artisan migrate
php artisan serve
```

### 3. Run Flutter App

```bash
cd omzetku
flutter run
```

## Important: Configure API URL

Edit `omzetku/lib/services/api_service.dart` line 8:

- **Android Emulator**: `http://10.0.2.2:8000/api`
- **iOS Simulator**: `http://localhost:8000/api`
- **Physical Device**: `http://YOUR_IP:8000/api`

Find your IP:

- Windows: `ipconfig`
- Mac/Linux: `ifconfig`

## Test Accounts

Create test account via Register screen or use API:

```bash
POST http://localhost:8000/api/register
{
  "nama_lengkap": "Test User",
  "nama_usaha": "Warung Test",
  "nomor_telepon": "08123456789",
  "email": "test@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

## Features Now Working

✅ User authentication (Register/Login)
✅ Add/View/Delete transactions
✅ Search transaction history
✅ Real-time balance calculation
✅ Today's transaction filter
✅ Category-based icons and colors

See `INTEGRATION_GUIDE.md` for full documentation.
