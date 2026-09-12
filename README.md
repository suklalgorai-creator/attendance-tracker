# College Attendance Tracker

A beautiful, premium, and highly functional College Attendance Tracker built with React, Vite, and Firebase. Track your classes, monitor your streaks, and ensure you stay above your minimum attendance requirements with ease.

## ✨ Features

- **Automated Tracking**: The app automatically calculates how many classes have been held based on your configured class days and timetable.
- **GitHub Style Heatmap**: Visualize your attendance history at a glance with a beautiful contribution graph.
- **Premium UI**: Featuring Glassmorphism, animated Mesh Gradients, and a seamless Light/Dark mode toggle.
- **Offline-First Syncing**: Your data is saved instantly to local storage, and then synced to Firebase Firestore with a 5-second debounce to save on quota and guarantee data integrity even on spotty connections.
- **Badges & Streaks**: Gamify your college attendance! Keep a daily streak and earn Bronze, Silver, and Gold badges based on your performance.
- **Admin Dashboard**: A secure portal for authorized admins to view the statistics of all registered users.

## 🚀 Tech Stack

- **Frontend**: React (Vite)
- **Styling**: Vanilla CSS (Responsive Grid & Custom Variables)
- **Authentication**: Firebase Google Auth
- **Database**: Firebase Cloud Firestore

## 🛠️ Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/suklalgorai-creator/attendance-tracker.git
   cd attendance-tracker
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Configure Environment Variables:**
   - Copy the `.env.example` file to `.env`
   - Fill in your Firebase config keys.
   ```bash
   cp .env.example .env
   ```

4. **Deploy Firestore Rules:**
   Copy the contents of `firestore.rules` into your Firebase Console to secure the database.

5. **Start the Development Server:**
   ```bash
   npm run dev
   ```
   Open `http://localhost:5173` to view it in the browser.

## 🔒 Security

We take security seriously. Read our [Security Policy](SECURITY.md) for information on reporting vulnerabilities and setting up Firebase Rules properly.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! 
Feel free to check out the issues page if you want to contribute.

---
Built with ❤️ by Suklal Gorai
