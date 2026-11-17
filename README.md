# 🎓 College Attendance Tracker

A unified multi-platform attendance tracking ecosystem containing a **React Progressive Web App (PWA)** and a **Flutter Offline-First Mobile App**.

---

## 📂 Repository Structure

```
COLLEGE ATTENDANCE TRACKER/
│
├── 🌐 react_app/               # React Web Application & PWA
│   ├── api/                    # Vercel Serverless Functions
│   ├── public/                 # Static web assets, manifest & service worker
│   ├── src/                    # React components, pages, context, and utilities
│   ├── tests/                  # Test suites for attendance logic & migrations
│   ├── vite.config.js          # Vite build config
│   └── package.json            # React app dependencies & scripts
│
├── 📱 flutter_app/             # Flutter Mobile App (Android / iOS / Cross-Platform)
│   ├── android/                # Native Android code
│   ├── ios/                    # Native iOS code
│   ├── lib/                    # Flutter Dart code (Clean / Feature architecture)
│   ├── test/                   # Flutter test suite
│   └── pubspec.yaml            # Flutter dependencies
│
├── .github/                    # GitHub Actions workflows (reminders cron)
├── firestore.rules             # Shared Firebase security rules
├── Master prompt for flutter.md # Migration blueprint & architectural guidelines
├── FLUTTER_CONVERSION_AND_100K_SCALING_ROADMAP.md # Conversion roadmap
├── CHANGELOG.md                # Release notes & version changes
└── SECURITY.md                 # Security & reporting policy
```

---

## ⚡ Quick Start

### 🌐 React Web App
```bash
cd react_app
npm install
npm run dev
```

### 📱 Flutter Mobile App
```bash
cd flutter_app
flutter pub get
flutter run
```

---

## 🤝 Contributing & License
Built with ❤️ by Suklal Gorai
