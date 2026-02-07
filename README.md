# TrustPoints Mobile App

<p align="center">
  <img src="assets/icon/icon.png" alt="TrustPoints Logo" width="120"/>
</p>

<p align="center">
  <strong>Platform Pengiriman P2P Berbasis Kepercayaan</strong>
</p>

<p align="center">
  <a href="#fitur">Fitur</a> •
  <a href="#screenshot">Screenshot</a> •
  <a href="#instalasi">Instalasi</a> •
  <a href="#arsitektur">Arsitektur</a> •
  <a href="#api">API</a>
</p>

---

## 📱 Tentang Aplikasi

**TrustPoints** adalah aplikasi mobile P2P (Peer-to-Peer) Delivery yang memungkinkan pengguna untuk saling membantu mengirimkan barang. Dengan sistem poin kepercayaan, pengguna dapat menjadi **Pengirim** (meminta barang dikirimkan) atau **Hunter** (mengantarkan barang orang lain).

### Konsep Utama

- **Trust Points (pts)**: Mata uang dalam aplikasi. `1 pts = Rp100`
- **Sender**: Pengguna yang membuat order dan membayar points
- **Hunter**: Pengguna yang mengambil dan mengantarkan order, mendapat points sebagai reward
- **Trust Score**: Rating kepercayaan pengguna berdasarkan performa pengiriman

---

## ✨ Fitur

### 🔐 Autentikasi

- [x] Registrasi akun baru
- [x] Login dengan email & password
- [x] Logout
- [x] Auto-login dengan secure token storage
- [x] Ubah password

### 👤 Profil Pengguna

- [x] Lihat profil lengkap
- [x] Edit nama & foto profil
- [x] Set alamat default dengan picker maps
- [x] Lihat trust score & total points
- [x] Preferensi bahasa (ID/EN)

### 📦 Manajemen Order

#### Sebagai Sender (Pengirim)

- [x] Buat order pengiriman baru
- [x] Pilih kategori barang (Makanan, Dokumen, Elektronik, Fashion, Groceries, Obat, Lainnya)
- [x] Set lokasi pickup & delivery dengan maps
- [x] Upload foto barang
- [x] Tentukan reward points untuk hunter
- [x] Lihat daftar order saya
- [x] Batalkan order (jika belum diklaim)
- [x] Chat dengan hunter

#### Sebagai Hunter (Pengambil)

- [x] Lihat order tersedia di sekitar
- [x] Filter berdasarkan kategori
- [x] Lihat detail order & estimasi jarak
- [x] Klaim order
- [x] Update status: Pickup → In Transit → Delivered
- [x] Chat dengan sender
- [x] Dapatkan points setelah selesai

### 💰 Wallet & Points

- [x] Lihat saldo points saat ini
- [x] Konversi otomatis ke Rupiah
- [x] Riwayat transaksi (earn/redeem)
- [x] Transfer points ke user lain
- [x] Top up points (simulasi)
- [x] Redeem points (simulasi)

### 💬 Chat Real-time

- [x] Chat langsung dengan sender/hunter
- [x] WebSocket untuk pesan real-time
- [x] Notifikasi pesan baru
- [x] Riwayat chat per order

### 🗺️ Lokasi & Maps

- [x] Deteksi lokasi saat ini
- [x] Pilih lokasi dari maps
- [x] Geocoding alamat
- [x] Hitung jarak & estimasi
- [x] Tampilkan order nearby

### 📊 Dashboard & Aktivitas

- [x] Dashboard overview
- [x] Statistik order (selesai, pending, dll)
- [x] Riwayat aktivitas terbaru
- [x] Quick actions

---

## 📸 Screenshot

|                Home                |                 Orders                 |              Create Order              |                 Profile                  |
| :--------------------------------: | :------------------------------------: | :------------------------------------: | :--------------------------------------: |
| ![Home](docs/screenshots/home.png) | ![Orders](docs/screenshots/orders.png) | ![Create](docs/screenshots/create.png) | ![Profile](docs/screenshots/profile.png) |

|                Login                 |              Order Detail              |                Chat                |                 Wallet                 |
| :----------------------------------: | :------------------------------------: | :--------------------------------: | :------------------------------------: |
| ![Login](docs/screenshots/login.png) | ![Detail](docs/screenshots/detail.png) | ![Chat](docs/screenshots/chat.png) | ![Wallet](docs/screenshots/wallet.png) |

---

## 🛠️ Tech Stack

| Kategori             | Teknologi                               |
| -------------------- | --------------------------------------- |
| **Framework**        | Flutter 3.9+                            |
| **Language**         | Dart 3.9+                               |
| **State Management** | Provider                                |
| **HTTP Client**      | http package                            |
| **Real-time**        | Socket.IO Client                        |
| **Local Storage**    | SharedPreferences, FlutterSecureStorage |
| **Maps**             | Flutter Map + OpenStreetMap             |
| **Location**         | Geolocator                              |
| **Image**            | Image Picker                            |
| **Date**             | intl                                    |

---

## 📁 Struktur Project

```
lib/
├── main.dart                    # Entry point aplikasi
├── config/
│   ├── api_config.dart          # Konfigurasi API endpoints
│   └── app_theme.dart           # Theme & styling aplikasi
├── models/
│   ├── user_model.dart          # Model User & DefaultAddress
│   ├── order_model.dart         # Model Order, OrderItem, Location
│   └── chat_model.dart          # Model ChatMessage
├── providers/
│   ├── auth_provider.dart       # State management autentikasi
│   └── order_provider.dart      # State management orders
├── services/
│   ├── api_service.dart         # Base HTTP service
│   ├── auth_service.dart        # Service autentikasi
│   ├── order_service.dart       # Service orders CRUD
│   ├── wallet_service.dart      # Service wallet/points
│   ├── activity_service.dart    # Service aktivitas
│   ├── chat_service.dart        # Service chat REST
│   └── socket_service.dart      # WebSocket service
└── screens/
    ├── login_screen.dart        # Halaman login
    ├── register_screen.dart     # Halaman registrasi
    ├── home_screen.dart         # Dashboard utama
    ├── profile_screen.dart      # Halaman profil
    ├── edit_profile_screen.dart # Edit profil
    ├── change_password_screen.dart
    ├── default_address_screen.dart
    ├── location_picker_screen.dart
    └── orders/
        ├── create_order_screen.dart    # Buat order baru
        ├── available_orders_screen.dart # Order tersedia
        ├── my_orders_screen.dart       # Order saya
        ├── order_detail_screen.dart    # Detail order
        ├── order_chat_screen.dart      # Chat order
        └── widgets/                    # Reusable widgets
```

---

## 🚀 Instalasi

### Prerequisites

- Flutter SDK 3.9+
- Dart SDK 3.9+
- Android Studio / VS Code
- Android SDK (untuk Android)
- Xcode (untuk iOS, macOS only)

### Setup

1. **Clone repository**

   ```bash
   git clone https://github.com/yourusername/trustpoints.git
   cd trustpoints/mobile/trustpoint
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Konfigurasi API URL**

   Edit `lib/config/api_config.dart`:

   ```dart
   class ApiConfig {
     // Untuk Android Emulator
     static const String baseUrl = 'http://10.0.2.2:5000';

     // Untuk iOS Simulator
     // static const String baseUrl = 'http://localhost:5000';

     // Untuk Device Fisik (ganti dengan IP komputer)
     // static const String baseUrl = 'http://192.168.x.x:5000';
   }
   ```

4. **Jalankan aplikasi**

   ```bash
   # Debug mode
   flutter run

   # Release mode
   flutter run --release
   ```

### Build APK

```bash
# Build APK debug
flutter build apk --debug

# Build APK release
flutter build apk --release

# Build App Bundle (untuk Play Store)
flutter build appbundle --release
```

### Build iOS

```bash
# Build iOS
flutter build ios --release

# Open in Xcode
open ios/Runner.xcworkspace
```

---

## 🔌 API Integration

### Base URL

```
Development: http://localhost:5000
Production: https://api.trustpoints.com
```

### Endpoints

| Method       | Endpoint                       | Deskripsi              |
| ------------ | ------------------------------ | ---------------------- |
| **Auth**     |                                |                        |
| POST         | `/api/register`                | Registrasi user baru   |
| POST         | `/api/login`                   | Login user             |
| **Profile**  |                                |                        |
| GET          | `/api/profile`                 | Get profil user        |
| PUT          | `/api/profile/edit`            | Update profil          |
| PUT          | `/api/profile/change-password` | Ubah password          |
| **Orders**   |                                |                        |
| POST         | `/api/orders`                  | Buat order baru        |
| GET          | `/api/orders/available`        | Order tersedia         |
| GET          | `/api/orders/nearby`           | Order di sekitar       |
| GET          | `/api/orders/:id`              | Detail order           |
| PUT          | `/api/orders/claim/:id`        | Klaim order            |
| PUT          | `/api/orders/pickup/:id`       | Pickup order           |
| PUT          | `/api/orders/deliver/:id`      | Selesaikan order       |
| PUT          | `/api/orders/cancel/:id`       | Batalkan order         |
| GET          | `/api/orders/my-orders`        | Order saya (sender)    |
| GET          | `/api/orders/my-deliveries`    | Delivery saya (hunter) |
| **Wallet**   |                                |                        |
| GET          | `/api/wallet/balance`          | Saldo points           |
| POST         | `/api/wallet/earn`             | Top up points          |
| POST         | `/api/wallet/redeem`           | Redeem points          |
| POST         | `/api/wallet/transfer`         | Transfer points        |
| **Activity** |                                |                        |
| GET          | `/api/activity/recent`         | Aktivitas terbaru      |
| GET          | `/api/activity/history`        | Riwayat aktivitas      |
| **Chat**     |                                |                        |
| GET          | `/api/chat/:orderId`           | Riwayat chat           |
| POST         | `/api/chat/:orderId`           | Kirim pesan            |

### WebSocket Events

```javascript
// Connect
socket.connect('ws://localhost:5000')

// Join order room
socket.emit('join_order', { order_id: '...' })

// Send message
socket.emit('send_message', {
  order_id: '...',
  message: '...',
  sender_id: '...'
})

// Receive message
socket.on('new_message', (data) => { ... })

// Order status update
socket.on('order_update', (data) => { ... })
```

---

## 🎨 Theme & Styling

### Warna Utama

```dart
// Primary Gradient
primaryStart: Color(0xFF667EEA)  // Indigo
primaryEnd: Color(0xFF764BA2)    // Purple

// Background
background: Color(0xFFF8F9FE)

// Text
textPrimary: Color(0xFF1A1A2E)
textSecondary: Color(0xFF6B7280)

// Status Colors
success: Color(0xFF00C853)
warning: Color(0xFFFFB300)
error: Color(0xFFE53935)
info: Color(0xFF2196F3)
```

### Typography

```dart
// Headings
h1: 28px, Bold
h2: 24px, Bold
h3: 20px, SemiBold

// Body
body1: 16px, Regular
body2: 14px, Regular

// Caption
caption: 12px, Regular
```

---

## 📊 Model Data

### User

```dart
class User {
  String id;
  String fullName;
  String email;
  String? profilePicture;
  double trustScore;      // 0.0 - 5.0
  int points;             // 1 pts = Rp100
  String languagePreference;
  DefaultAddress? defaultAddress;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### Order

```dart
class Order {
  String id;
  String orderId;         // TP-YYYYMMDDHHMMSS-XXXXXXXX
  String senderId;
  String? hunterId;
  String status;          // PENDING, CLAIMED, IN_TRANSIT, DELIVERED, CANCELLED
  OrderItem item;
  OrderLocation pickupLocation;
  OrderLocation deliveryLocation;
  double distanceKm;
  int pointsCost;         // Yang dibayar sender
  int trustPointsReward;  // Yang didapat hunter
  String? notes;
  DateTime createdAt;
  DateTime? claimedAt;
  DateTime? pickedUpAt;
  DateTime? deliveredAt;
}
```

### Order Status Flow

```
PENDING → CLAIMED → IN_TRANSIT → DELIVERED
    ↓         ↓
CANCELLED  CANCELLED
```

---

## 🔒 Keamanan

- **Token Storage**: JWT disimpan di FlutterSecureStorage (encrypted)
- **Auto Logout**: Token expired otomatis logout
- **API Auth**: Semua request authenticated dengan Bearer token
- **Password**: Minimal 6 karakter, di-hash dengan bcrypt di server

---

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Coverage
flutter test --coverage
```

---

## 📝 Catatan Pengembangan

### TODO

- [ ] Push notifications
- [ ] Payment gateway integration
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Order tracking real-time
- [ ] Rating & review system
- [ ] Image compression

### Known Issues

- Maps tile loading lambat di koneksi lemah
- Socket reconnect perlu improvement

---

## 🤝 Contributing

1. Fork repository
2. Buat branch fitur (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 📞 Contact

- **Email**: support@trustpoints.com
- **Website**: https://trustpoints.com
- **GitHub**: https://github.com/trustpoints

---

<p align="center">
  Made with ❤️ using Flutter
</p>
