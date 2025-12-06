# Firebase Setup untuk OmzetKu

## ✅ Instalasi Selesai

### Packages Terinstall:

```yaml
firebase_core: ^4.2.1
firebase_auth: ^6.1.2
cloud_firestore: ^6.1.0
firebase_storage: ^13.0.4
```

### File Konfigurasi:

- ✅ `lib/firebase_options.dart` - Auto-generated configuration
- ✅ Firebase Project: **omzet-ku**
- ✅ Platform Support: Android, iOS, macOS, Web, Windows

### Konfigurasi main.dart:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // ... rest of initialization
}
```

## Firebase Services Available:

### 1. Firebase Authentication

```dart
import 'package:firebase_auth/firebase_auth.dart';

// Login
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);

// Register
await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

// Logout
await FirebaseAuth.instance.signOut();
```

### 2. Cloud Firestore

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Add data
await FirebaseFirestore.instance.collection('transactions').add({
  'title': 'Transaction',
  'amount': 50000,
  'timestamp': FieldValue.serverTimestamp(),
});

// Get data
final snapshot = await FirebaseFirestore.instance
    .collection('transactions')
    .where('userId', isEqualTo: userId)
    .get();
```

### 3. Firebase Storage

```dart
import 'package:firebase_storage/firebase_storage.dart';

// Upload file
final storageRef = FirebaseStorage.instance.ref();
final profileRef = storageRef.child('profiles/$userId.jpg');
await profileRef.putFile(imageFile);

// Get download URL
String downloadURL = await profileRef.getDownloadURL();
```

## Langkah Selanjutnya:

### Option 1: Migrasi dari Laravel API ke Firebase

- Ganti `ApiService` dengan Firebase services
- Gunakan Firestore untuk transactions & products
- Gunakan Firebase Auth untuk authentication
- Gunakan Storage untuk photo uploads

### Option 2: Hybrid Approach

- Tetap gunakan Laravel API untuk backend
- Tambahkan Firebase untuk:
  - Push notifications (Firebase Cloud Messaging)
  - Real-time sync (Firestore)
  - File storage (Firebase Storage)
  - Analytics (Firebase Analytics)

## Firebase Console:

🔗 https://console.firebase.google.com/project/omzet-ku

## Cara Running:

```bash
# Android
flutter run

# Web
flutter run -d chrome

# Build APK
flutter build apk --release
```

## Notes:

- ✅ Firebase sudah terintegrasi di main.dart
- ✅ Semua platform (Android, iOS, Web, Windows, macOS) sudah terdaftar
- ⚠️ Untuk production, tambahkan `.env` atau secure config management
- ⚠️ Enable Firestore & Storage di Firebase Console jika belum
- ⚠️ Set up Security Rules di Firestore untuk production
