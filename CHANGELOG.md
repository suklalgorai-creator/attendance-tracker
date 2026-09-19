# College Attendance Tracker - Changelog

## 🚀 Performance Optimizations (Latest Update)
The app underwent a significant performance overhaul, particularly targeting lag on mobile devices caused by heavy CSS rendering.

### What was fixed?
- **CSS Rendering Blocks:** Removed the extreme `blur(100px)` filter from the animated mesh background on mobile views, which was causing severe GPU thrashing.
- **Layer Optimization:** Reduced the usage of `backdrop-filter: blur()` across 6 different component layers (like modals, icons, and banners) in `components.css`.
- **React Re-renders:** 
  - Memoized `CalendarView` using `React.memo` to prevent the heavy calendar grid from re-rendering unnecessarily.
  - Hardened `useMemo` dependencies inside `AppContext.jsx` so that the `stats` object is only recalculated when relevant data actually changes, not on every state update.
  - Removed double `computeStats` calls.
- **Bundle Cleanup:** Removed server-only dependencies like `firebase-admin` from the frontend build and stripped out dead code/polyfills (`window.storage`).

## 📝 Feature: Sticky Notes with Reminders
We introduced a brand new "Sticky Notes" module inside the application, replacing the placeholder "My Resources" section. This feature acts as a quick-access dashboard for college-related reminders, links, and temporary notes.

### Key Capabilities
- **Color-Coded Notes:** Users can create notes and assign them one of 5 distinct pastel colors (Amber, Emerald, Blue, Pink, Gray) or stick to the default dark theme.
- **Masonry Layout:** Notes are displayed in a responsive, beautiful masonry grid on `/notes`.
- **Quick Actions:** Easily edit by tapping a note, or delete it using the trash icon directly on the card.
- **Cross-Device Sync:** Because notes are stored in the core `data` object within `AppContext.jsx`, they are automatically synced to Firebase (if the user is logged in) and persist across devices.

### Smart Reminder System (Push Notifications)
- **Time-based Triggers:** Users can set a specific Date & Time for a note using the `datetime-local` picker in the Note Editor.
- **Background Polling:** The app leverages the existing `useReminders.js` hook. It polls every 60 seconds to check both Attendance and Note reminders.
- **Web Notifications:** If a note's reminder time is reached or passed (and hasn't been notified yet), the app dispatches a system Web Notification (Push Notification via Service Worker on mobile, or Browser Notification on desktop).
- **Anti-Spam Check:** The system uses `localStorage` (`note_notified_{noteId}`) to ensure a reminder notification is only fired exactly once per note.

## 🗺️ Navigation Changes
- **Dashboard Widget:** A new quick-access card was added to the `DashboardPage.jsx` (right beneath the main hero stats) to instantly jump to Sticky Notes.
- **Sidebar & Drawer:** The "My Resources" alert buttons in `DesktopLayout.jsx` and `DrawerMenu.jsx` were permanently replaced with proper Router Links pointing to `/notes`.

## 🛠️ Tech Stack & New Dependencies
- **UUID:** Added `uuid` (`npm install uuid`) to generate secure, unique identifiers for every new sticky note created.
- **React Router:** Leveraged `NavLink` and `Link` for seamless SPA transitions into the notes module.
