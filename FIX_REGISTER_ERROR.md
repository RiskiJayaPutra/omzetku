# 🔧 Fix Register Error

## Problem

Error: `ClientException: Failed to fetch, uri=http://localhost:8000/api/register`

## Penyebab

1. Laravel server tidak running
2. CORS belum dikonfigurasi untuk web browser
3. Koneksi timeout

## Solusi yang Sudah Diterapkan

### ✅ 1. CORS Configuration

File baru: `omzetku-api/config/cors.php`

```php
'paths' => ['api/*', 'sanctum/csrf-cookie'],
'allowed_origins' => ['*'],
'allowed_methods' => ['*'],
'allowed_headers' => ['*'],
```

### ✅ 2. Bootstrap Middleware Update

File: `omzetku-api/bootstrap/app.php`

```php
->withMiddleware(function (Middleware $middleware): void {
    $middleware->api(prepend: [
        \Illuminate\Http\Middleware\HandleCors::class,
    ]);
})
```

### ✅ 3. API Service Enhanced

File: `omzetku/lib/services/api_service.dart`

- ✅ Tambah timeout handler
- ✅ Tambah debugging logs
- ✅ Accept header untuk JSON

## Cara Test Sekarang

### 1. Pastikan Laravel Server Running

Cek terminal yang menunjukkan:

```
INFO  Server running on [http://127.0.0.1:8000]
```

### 2. Test API dengan Browser

Buka Chrome, tekan F12 (Developer Tools), lalu paste di Console:

```javascript
fetch("http://localhost:8000/api/register", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
  body: JSON.stringify({
    nama_lengkap: "Test User",
    nama_usaha: "Test Store",
    nomor_telepon: "08123456789",
    email: "test" + Date.now() + "@test.com",
    password: "password123",
    password_confirmation: "password123",
  }),
})
  .then((r) => r.json())
  .then((d) => console.log("✅ Success:", d))
  .catch((e) => console.error("❌ Error:", e));
```

### 3. Test di Flutter App

Di app yang sudah terbuka:

1. Klik "Daftar Akun Baru"
2. Isi form
3. Klik "Daftar"
4. Lihat Console di VS Code untuk debug logs:
   - 🔵 = Info
   - 🔴 = Error

## Debug Logs

Sekarang saat register, Anda akan melihat di Console:

```
🔵 Attempting to register to: http://localhost:8000/api/register
🔵 Response status: 201
🔵 Response body: {...}
```

Atau jika error:

```
🔴 Register error: [error detail]
```

## Jika Masih Error

### Option A: Restart Semua

```bash
# Terminal 1 - Stop Flutter
# Tekan 'q' di terminal Flutter

# Terminal 2 - Restart Laravel
Ctrl+C
php artisan serve

# Terminal 1 - Start Flutter lagi
flutter run -d chrome
```

### Option B: Test API Manual

```bash
# Test dari PowerShell
$body = @{
    nama_lengkap = "Test User"
    nama_usaha = "Test Store"
    nomor_telepon = "08123456789"
    email = "test@test.com"
    password = "password123"
    password_confirmation = "password123"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8000/api/register" -Method POST -Body $body -ContentType "application/json"
```

### Option C: Cek Laravel Logs

```bash
cd omzetku-api
tail -f storage/logs/laravel.log
```

## Status Saat Ini

- ✅ Laravel Server: Running
- ✅ Flutter App: Running di Chrome
- ✅ CORS: Configured
- ✅ API Service: Enhanced with debugging
- 🔄 Ready for Testing

## Next Steps

1. Buka Chrome Developer Tools (F12)
2. Pergi ke tab "Console"
3. Coba register lagi
4. Lihat log messages (🔵/🔴)
5. Report hasil testing

---

**Updated**: November 17, 2025
