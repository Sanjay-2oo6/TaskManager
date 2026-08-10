# Task Manager - Frontend (Flutter Mobile App)

**Tech Stack:** Flutter / Dart  
**Platforms:** Android, iOS, Windows, Linux, macOS, Web

---

## 📱 Overview

Cross-platform mobile application for the INNO TECH HUB Task Manager system. Provides role-based interfaces for Members, Admins, and Super Admins.

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- VS Code with Flutter extension (recommended)

### Installation

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# For specific platform
flutter run -d chrome        # Web
flutter run -d windows       # Windows
flutter run -d android       # Android
flutter run -d ios           # iOS
```

---

## 📁 Project Structure

```
frontend/
├── lib/
│   ├── core/              # Core utilities, theme, constants
│   ├── data/              # Data layer (models, API clients, services)
│   ├── presentation/      # UI layer (screens, widgets)
│   └── state/             # State management (Riverpod providers)
├── android/               # Android platform code
├── ios/                   # iOS platform code
├── windows/               # Windows platform code
├── web/                   # Web platform code
├── assets/                # Images, fonts, other assets
└── pubspec.yaml           # Dependencies
```

---

## 🔧 Configuration

### Environment Variables

Create `.env` file in the `frontend/` directory:

```env
API_BASE_URL=http://localhost:5000/api/v1
```

For production/remote testing, update the URL:

```env
API_BASE_URL=https://your-backend-url.com/api/v1
```

---

## 🎨 Features by Role

### Member (Team Member)
- View assigned tasks
- Update task status
- Submit work with photos
- Chat on tasks
- View own statistics

### Admin (Organization Admin)
- All Member features
- Create and assign tasks
- Manage team members
- Approve/reject submissions
- View analytics
- Organization settings

### Super Admin (Platform Owner)
- Create organizations
- Create admin accounts
- Manage platform settings
- View platform statistics
- **Cannot access organization data** (privacy)

---

## 🛠️ Development

### Run in Debug Mode
```bash
flutter run
```

### Build for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```

**iOS (requires macOS):**
```bash
flutter build ios --release
```

**Windows:**
```bash
flutter build windows --release
```

**Web:**
```bash
flutter build web --release
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

---

## 📦 Dependencies

Key packages used:
- `flutter_riverpod` - State management
- `http` - API requests
- `shared_preferences` - Local storage
- `image_picker` - Photo capture
- `file_picker` - File uploads
- `socket_io_client` - Real-time updates

See `pubspec.yaml` for complete list.

---

## 🔗 Backend Integration

This frontend connects to the Node.js backend API located in `../backend/`.

**API Base URL:** Configure in `.env` file

**Authentication:** JWT tokens stored in secure local storage

**Real-time:** WebSocket connection for live updates

---

## 📱 Platform-Specific Notes

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 33
- Permissions: Camera, Storage, Internet

### iOS
- Minimum version: iOS 12.0
- Permissions: Camera, Photo Library, Network

### Windows
- Minimum: Windows 10
- No special permissions required

---

## 🐛 Troubleshooting

**Issue: "Connection refused" error**
- Check backend is running (`cd ../backend && npm run dev`)
- Verify API_BASE_URL in `.env`
- For Android emulator, use `10.0.2.2` instead of `localhost`

**Issue: Build errors after pulling latest code**
```bash
flutter clean
flutter pub get
flutter run
```

**Issue: Gradle build fails (Android)**
```bash
cd android
.\gradlew clean
cd ..
flutter run
```

---

## 📚 Related Documentation

- [API Reference](../docs/API_REFERENCE.md)
- [User Guide](../docs/USER_GUIDE.md)
- [Technical Documentation](../docs/TECHNICAL_DOCUMENTATION.md)
- [Roles & Permissions](../docs/ROLES_AND_PERMISSIONS.md)

---

## 🤝 Contributing

1. Create a feature branch from `main`
2. Make your changes
3. Test on all target platforms
4. Submit a pull request

---

**Version:** 2.0.0  
**Last Updated:** July 18, 2026  
**Maintained by:** INNO TECH HUB
