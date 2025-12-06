# API Configuration for OmzetKu

## Configuration Options

### Development (Local Testing)

**Android Emulator:**

```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

**iOS Simulator:**

```dart
static const String baseUrl = 'http://localhost:8000/api';
```

**Physical Device (Same Network):**

```dart
static const String baseUrl = 'http://192.168.1.X:8000/api';
// Replace X with your computer's IP address
```

### Finding Your IP Address

**Windows:**

```bash
ipconfig
# Look for IPv4 Address under your active network adapter
```

**Mac/Linux:**

```bash
ifconfig
# or
ip addr show
# Look for inet address
```

### Production

For production, replace with your actual API URL:

```dart
static const String baseUrl = 'https://your-domain.com/api';
```

## Current Configuration

The API service is located in:
`lib/services/api_service.dart`

Default setting:

```dart
static const String baseUrl = 'http://localhost:8000/api';
```

## Laravel Server

Make sure your Laravel server is running:

```bash
cd omzetku-api
php artisan serve
```

This will start the server at `http://localhost:8000`

## Network Security (Android)

For HTTP connections on Android, add to `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

Or create a network security config file.
