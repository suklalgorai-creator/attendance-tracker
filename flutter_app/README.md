# 📱 College Attendance Tracker — Flutter Mobile App

Offline-first, high-performance Flutter mobile application for tracking college attendance, bunking allowances, and daily reminders.

---

## 📁 Architecture & Directory Structure

```
flutter_app/
├── android/              # Native Android configuration
├── ios/                  # Native iOS configuration
├── lib/
│   ├── core/
│   │   ├── constants/    # Theme tokens, colors, static keys
│   │   ├── services/     # Hive local database, notifications, ads
│   │   └── utils/        # Attendance math calculator & safe bunk engine
│   ├── models/           # Data models (Subject, AttendanceLog, etc.)
│   ├── screens/          # Dashboard, Add Subject, Analytics, Settings
│   ├── widgets/          # Reusable UI widgets
│   └── main.dart         # Flutter app entrypoint & theme config
├── test/                 # Flutter unit & widget tests
└── pubspec.yaml          # Dependencies & assets configuration
```

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the App
Connect a device or start an emulator, then:
```bash
flutter run
```

### 3. Run Tests
```bash
flutter test
```
