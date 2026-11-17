# 🌐 College Attendance Tracker — React Web App & PWA

Production React web application and Progressive Web App (PWA) with Vercel Serverless Functions and Firebase backend.

---

## 📁 Project Structure

```
react_app/
├── api/                  # Vercel Serverless Functions
│   ├── leaderboard.js    # Global student ranking & stats
│   └── send-notification.js # Push notification & automated cron reminders
├── public/               # Public assets, icons, manifest & service worker
│   ├── firebase-messaging-sw.js
│   ├── icon.svg
│   ├── logo.jpg
│   └── my-qr.png
├── src/                  # React Application Code
│   ├── components/       # UI Components (Heatmap, Ring, Stepper, etc.)
│   ├── context/          # State management (AppContext)
│   ├── hooks/            # Custom hooks (reminders, install prompt, media query)
│   ├── layouts/          # Responsive App, Desktop, and Mobile layouts
│   ├── pages/            # Dashboard, Leaderboard, Register, Settings, etc.
│   ├── services/         # Firebase sync, offline debounced sync
│   ├── styles/           # CSS design system (components, layout, global)
│   └── utils/            # Attendance calculations, date math, sync & backup
├── tests/                # Automated Node test runner suites
├── index.html            # Entry HTML
├── vite.config.js        # Vite + VitePWA configuration
└── package.json          # Node dependencies & scripts
```

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Fill in your Firebase credentials.

### 3. Run Development Server
```bash
npm run dev
```
Open `http://localhost:3000` (or `http://localhost:5173`).

### 4. Run Automated Tests
```bash
npm test
```

### 5. Production Build
```bash
npm run build
```
Build output will be generated inside `react_app/dist/`.
