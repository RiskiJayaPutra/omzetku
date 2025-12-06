# 🚀 Testing Guide - Login & Register

## Status Setup

✅ Database migration completed
✅ Laravel API ready  
✅ Flutter dependencies installed
✅ Login & Register screens integrated with API

## Langkah Testing

### 1. Start Laravel Server

Server sudah berjalan di terminal terpisah. Jika belum:

```bash
cd omzetku-api
php artisan serve
```

Pastikan muncul: `Server started on [http://localhost:8000]`

### 2. Run Flutter App

```bash
cd omzetku
flutter run
```

### 3. Test Register (Daftar Akun Baru)

Ketika app terbuka, Anda akan melihat **Login Screen**.

1. Klik tombol **"Daftar Akun Baru"**
2. Isi semua field:
   - **Nama Lengkap**: Tes User
   - **Nama Usaha**: Warung Tes
   - **Email**: test@example.com
   - **Nomor Telepon**: 08123456789
   - **Password**: password123
   - **Konfirmasi Password**: password123
3. ✅ Centang "Saya menyetujui Syarat & Ketentuan"
4. Klik tombol **"Daftar"**
5. ✅ Tunggu proses (loading indicator akan muncul)
6. ✅ Dialog "Registrasi Berhasil!" akan muncul
7. Klik **"OK"** untuk kembali ke login screen

### 4. Test Login

Setelah registrasi berhasil:

1. Di **Login Screen**, isi:
   - **Email**: test@example.com
   - **Password**: password123
2. Klik tombol **"Masuk"**
3. ✅ Loading indicator akan muncul
4. ✅ SnackBar "Login berhasil!" akan muncul (hijau)
5. ✅ Otomatis pindah ke **Halaman Utama**

### 5. Verifikasi Halaman Utama

Setelah login berhasil, Anda akan melihat:

✅ **Header** dengan:

- Saldo Saat Ini: Rp 0
- Pemasukan: Rp 0
- Pengeluaran: Rp 0

✅ **Section** "Transaksi Hari Ini" (kosong)

✅ **Bottom Navigation**:

- 🏠 Beranda (aktif)
- 🔍 Riwayat

✅ **Floating Action Button (+)** untuk tambah transaksi

### 6. Test Tambah Transaksi

1. Klik tombol **+ (FAB)**
2. Akan muncul screen **"Add Transaction"**
3. Tab **"Pengeluaran"** aktif default
4. Isi:
   - **Nominal**: 50000
   - **Nama Pengeluaran**: Belanja Mingguan
   - **Kategori**: Belanja (dropdown)
   - **Catatan**: Testing transaksi
5. Klik **"Simpan Transaksi"**
6. ✅ Kembali ke halaman utama
7. ✅ Transaksi muncul di list
8. ✅ Saldo berubah menjadi **-Rp 50,000**
9. ✅ Pengeluaran menjadi **Rp 50,000**

### 7. Test Pencarian Riwayat

1. Klik tab **"Riwayat"** di bottom nav
2. ✅ Semua transaksi tampil
3. Ketik di search bar: **"belanja"**
4. ✅ Hasil pencarian muncul real-time
5. Klik ❌ di search bar untuk clear
6. ✅ Semua transaksi tampil kembali

### 8. Test Hapus Transaksi

1. Tap salah satu transaksi di list
2. ✅ Detail transaksi muncul
3. Klik icon **🗑️ Delete** di app bar
4. Dialog konfirmasi muncul
5. Klik **"Hapus"**
6. ✅ Transaksi terhapus
7. ✅ Saldo ter-update
8. ✅ Kembali ke home screen

---

## Troubleshooting

### ❌ Error: Connection Refused

**Penyebab**: Laravel server tidak running

**Solusi**:

```bash
cd omzetku-api
php artisan serve
```

### ❌ Error: Login/Register Gagal

**Penyebab**: API URL tidak cocok dengan platform

**Solusi**: Edit `lib/services/api_service.dart` line 8:

- Android Emulator: `http://10.0.2.2:8000/api`
- iOS Simulator: `http://localhost:8000/api`
- Physical Device: `http://YOUR_IP:8000/api`

### ❌ Error: Email already exists

**Penyebab**: Email sudah terdaftar

**Solusi**: Gunakan email lain atau hapus data di database:

```sql
DELETE FROM users WHERE email = 'test@example.com';
```

### ❌ Error: 401 Unauthorized

**Penyebab**: Token expired atau tidak valid

**Solusi**: Logout dan login kembali

---

## Verifikasi Database

### Cek User Berhasil Register

```bash
cd omzetku-api
php artisan tinker
```

Dalam tinker:

```php
\App\Models\User::all();
// Atau
\App\Models\User::where('email', 'test@example.com')->first();
```

### Cek Transaksi Tersimpan

```php
\App\Models\Transaction::all();
// Atau transaksi user tertentu
\App\Models\Transaction::where('user_id', 1)->get();
```

---

## Expected Results

### ✅ Registrasi Berhasil

- User tersimpan di tabel `users`
- Password ter-hash
- Field UMKM terisi (nama_lengkap, nama_usaha, nomor_telepon)

### ✅ Login Berhasil

- Token generated dan disimpan di SharedPreferences
- Redirect ke halaman utama
- Token digunakan untuk semua API call selanjutnya

### ✅ Halaman Utama

- Load transaksi dari database
- Hitung saldo real-time
- CRUD transaksi berfungsi
- Search berfungsi

---

## Test Account

Jika ingin test dengan data yang sudah ada:

**Method 1: Via App**

- Register akun baru lewat app

**Method 2: Via Tinker**

```bash
php artisan tinker
```

```php
\App\Models\User::create([
    'nama_lengkap' => 'Demo User',
    'nama_usaha' => 'Warung Demo',
    'nomor_telepon' => '08123456789',
    'email' => 'demo@example.com',
    'password' => bcrypt('password123')
]);
```

**Method 3: Via Postman/Thunder Client**

```
POST http://localhost:8000/api/register
Content-Type: application/json

{
  "nama_lengkap": "Demo User",
  "nama_usaha": "Warung Demo",
  "nomor_telepon": "08123456789",
  "email": "demo@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

---

## Success Criteria Checklist

### Registration Flow

- [ ] Form validation berfungsi
- [ ] Checkbox syarat & ketentuan wajib dicentang
- [ ] Password match validation
- [ ] API call berhasil
- [ ] User tersimpan di database
- [ ] Dialog sukses muncul
- [ ] Redirect ke login screen

### Login Flow

- [ ] Form validation berfungsi
- [ ] API call berhasil
- [ ] Token disimpan di SharedPreferences
- [ ] SnackBar sukses muncul
- [ ] Redirect ke home screen
- [ ] User info loaded

### Main Screen Flow

- [ ] Load transactions dari API
- [ ] Saldo terhitung dengan benar
- [ ] Tambah transaksi berhasil
- [ ] Transaksi muncul di list
- [ ] Delete transaksi berhasil
- [ ] Search transaksi berfungsi
- [ ] Pull-to-refresh bekerja

---

**Status**: ✅ READY FOR TESTING

Silakan jalankan test sesuai langkah di atas dan laporkan jika ada masalah!
