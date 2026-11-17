# 📋 PHASE 0: Discovery & Comprehensive Audit Report

> **Project**: College Attendance Tracker (React ➔ Flutter Migration)  
> **Source of Truth**: `react_app/` (React 18 + Vite + PWA + Firebase)  
> **Target Production Codebase**: `flutter_app/` (Flutter 3.x / Dart 3.x Null Safety)  
> **Audit Date**: 17-Nov-2026  
> **Status**: Completed — Awaiting User Sign-off to begin Phase 1  

---

## 1. Executive Summary & Objective

The user has mandated an exact, 1:1 fidelity migration from the existing React Progressive Web App (`react_app/`) into a production-ready Flutter app (`flutter_app/`) on the `flutter` branch:
> *"flutter me conversion ko completely same rakhna hoga react wala ka no change sab same ui/ux colors fonts, design etc exact just convert the app into flutter"*

Phase 0 performs an exhaustive code-level audit of the React codebase and evaluates the existing Flutter baseline to guarantee that:
1. Every screen, component, dialog, and micro-interaction is cataloged with exact colors, typography, and layout rules.
2. The complete data model (Schema Version 2, legacy records, Firestore structure) is preserved without data loss.
3. The exact mathematical engine (`attendance.js` with IEEE 754 float epsilon handling) is replicated in Dart with zero deviations.
4. A concrete, zero-guesswork phased roadmap is prepared.

---

## 2. Design System & Theming Audit (Exact 1:1 Parity)

### 🎨 Typography
- **Font Family**: Google Fonts **`Outfit`** (`'Outfit', -apple-system, sans-serif`)  
  *(Note: The previous draft assumed Inter; audit confirms the React stylesheet imports Outfit at weights 300, 400, 500, 600, 700, 800).*
- **Header Eyebrow**: 12px, font-weight 700, letter-spacing 1px, text-transform uppercase, color `var(--muted)`.
- **Title / Course Name**: 22px-28px, font-weight 800, color `var(--paper)`.
- **Stat Value**: 20px-24px, font-weight 800.
- **Body & Labels**: 14px-15px, font-weight 500-600.

### 🌗 Color Palette Tokens

| Token Name | Dark Theme Value (Default) | Light Theme Value | Purpose |
| :--- | :--- | :--- | :--- |
| `--bg-primary` | `#050505` (Deep Black) | `#F8FAFC` (Slate 50) | App scaffold background |
| `--surface` | `rgba(24, 24, 27, 0.65)` (Zinc 900 @ 65%) | `rgba(255, 255, 255, 0.70)` | Frosted glass cards |
| `--surface-solid` | `#18181B` (Zinc 900 solid) | `#FFFFFF` (Pure white) | Solid cards & dialogs |
| `--surface-hover` | `rgba(39, 39, 42, 0.85)` | `rgba(255, 255, 255, 0.95)` | Card hover / active |
| `--glass-border` | `rgba(255, 255, 255, 0.08)` | `rgba(0, 0, 0, 0.05)` | Card border gradient |
| `--paper` | `#FFFFFF` | `#0F172A` (Slate 900) | Primary text color |
| `--muted` | `#A1A1AA` (Zinc 400) | `#64748B` (Slate 500) | Secondary / subtitle text |
| `--ink-green` | `#10B981` (Emerald 500) | `#10B981` | Present / Safe / Target met |
| `--ink-green-soft`| `rgba(16, 185, 129, 0.15)` | `rgba(16, 185, 129, 0.15)` | Present button background |
| `--pen-red` | `#F43F5E` (Rose 500) | `#F43F5E` | Absent / Danger / Warning |
| `--pen-red-soft` | `rgba(244, 63, 94, 0.15)` | `rgba(244, 63, 94, 0.15)` | Absent button background |
| `--amber` | `#F59E0B` (Amber 500) | `#F59E0B` | Holiday / Guest alert / Streak |
| `--amber-soft` | `rgba(245, 158, 11, 0.15)` | `rgba(245, 158, 11, 0.15)` | Warning badges |
| `--rule` | `rgba(255, 255, 255, 0.06)` | `rgba(0, 0, 0, 0.06)` | Subtle dividers & borders |
| `--rule-bright` | `rgba(255, 255, 255, 0.12)` | `rgba(0, 0, 0, 0.12)` | Active borders |

### 💫 Background Mesh & Visual Effects
- Three floating radial gradient orbs (`--mesh-1: rgba(16, 185, 129, 0.15)`, `--mesh-2: rgba(244, 63, 94, 0.15)`, `--mesh-3: rgba(59, 130, 246, 0.15)`).
- Mobile optimization: Soft non-blocking background gradient without expensive runtime blur.

---

## 3. Application Navigation & Screen Inventory

### A. Navigation Architecture
- **Primary Shell**: Bottom Navigation Bar with 4 tabs:
  1. 🏠 **Home (`/`)**: `DashboardPage`
  2. 📅 **Register (`/register`)**: `RegisterPage`
  3. 🏆 **Leaderboard (`/leaderboard`)**: `LeaderboardPage`
  4. ⚙️ **Settings (`/settings`)**: `SettingsPage`
- **Side Drawer (`DrawerMenu`)**:
  - Menu Header with Close button.
  - Section 1: Additional Features (`Leaderboard`, `Sticky Notes` (`/notes`), `Export Data (CSV)`).
  - Section 2: App & Settings (`Install App`, `Switch to Light/Dark Mode`, `What's New Modal`, `Share App`, `Support Modal`).
- **Header Bar**:
  - Left: Hamburger Menu (Mobile) + Program & Course Eyebrows ("My Attendance").
  - Right: Theme Toggle button + Flame Streak Badge (`🔥 X`) that triggers `StreakPopup`.
  - Reminders Banner: Displayed when pending sessions are unmarked past reminder time.
  - Guest Banner: "⚠️ Data not backed up! Tap here to Sign in".

### B. Screen-by-Screen Inventory

| Screen | React File | Key Features & Elements |
| :--- | :--- | :--- |
| **Auth Screen** | `src/components/Auth.jsx` | Google Sign-In with popup/redirect, "Continue as Guest" local mode, feature highlights pill list, privacy note. |
| **Onboarding** | `src/pages/OnboardingPage.jsx` | First-time setup wizard: Name, Degree/Program selection, Semester, Start date, Minimum target %, Class days picker. |
| **Dashboard** | `src/pages/DashboardPage.jsx` | Pending attendance alert banner, Cloud sync status badge, Streak indicator, Hero attendance circular `Ring`, Quick stats (Conducted, Present, Status advice message), `Activity` card with `CalendarView`. |
| **Register** | `src/pages/RegisterPage.jsx` | View range toggle (`Week` / `Month` / `All`), Date list with `DayRow` items, quick buttons (`Present`, `Absent`, `Holiday/No class`, `Clear`), holiday indicator tags. |
| **Leaderboard**| `src/pages/LeaderboardPage.jsx`| User ranking by attendance %, streak badges, anonymized list, opt-in privacy switch, podium styling for top 3. |
| **Notes** | `src/pages/NotesPage.jsx` | Sticky notes masonry grid, Markdown formatting support (`ReactMarkdown`), color picker, deadline reminder badge, Floating Action Button (+). |
| **Settings** | `src/pages/SettingsPage.jsx` | User profile avatar card, Theme switch, Degree/Semester datalists, Class days `DayPicker`, Target %, Reminder time, Push notifications, JSON Backup export & restore with preview, Danger zone (Clear history). |
| **Admin View** | `src/components/AdminDashboard.jsx`| Lazy loaded admin screen: Total registered students, aggregated metrics, broadcast push notification trigger, global holidays manager. |

---

## 4. Mathematical Engine & Business Rules Audit

The mathematical engine in `react_app/src/utils/attendance.js` enforces precise college attendance policies:

### 1. Attendance Percentage
$$\text{Attendance \%} = \frac{\text{Present}}{\text{Conducted}} \times 100$$
*(If $\text{Conducted} \le 0$, returns `null` which displays "No attendance recorded")*

### 2. Maximum Safe Bunks (Can Miss Classes)
$$\text{Safe Bunks} = \max\left(0, \left\lfloor \frac{\text{Present} \times 100}{\text{Threshold}} - \text{Conducted} + 10^{-10} \right\rfloor\right)$$
- If current attendance $<$ threshold, returns `0`.
- The $+10^{-10}$ epsilon prevents floating point under-flooring (e.g. `3.0000000000000004` vs `2.9999999999999996`).

### 3. Required Recovery Classes (Need to Attend)
$$\text{Classes Needed} = \max\left(0, \left\lceil \frac{(\text{Threshold} \times \text{Conducted}) - (100 \times \text{Present})}{100 - \text{Threshold}} - 10^{-10} \right\rceil\right)$$
- If current attendance $\ge$ threshold, returns `0`.
- If $\text{Threshold} \ge 100$, returns `Infinity` (`stats.impossible = true` ➔ "100% target is unreachable").

### 4. Non-Penalizing Attendance States
- `CANCELLED`, `HOLIDAY`, and `UNMARKED` sessions strictly **do not reduce official attendance** and do not increment $\text{Conducted}$.
- `UNMARKED` sessions in the past trigger a warning banner without counting as absences.

---

## 5. Data Model & Firebase Architecture Audit

### Schema Version 2 Structure
```json
{
  "schemaVersion": 2,
  "name": "Student Name",
  "programName": "B.Tech CSE",
  "courseName": "Semester 5",
  "startDate": "2026-08-01",
  "minPercent": 75.0,
  "classDays": [1, 2, 3, 4, 5],
  "reminderTime": "18:00",
  "pushNotificationsEnabled": true,
  "subjects": [
    {
      "id": "sub-1",
      "name": "Operating Systems",
      "color": "#10B981",
      "active": true,
      "createdAt": "2026-08-01T00:00:00.000Z",
      "updatedAt": "2026-08-01T00:00:00.000Z",
      "deletedAt": null
    }
  ],
  "attendanceRecords": [
    {
      "id": "rec-1",
      "date": "2026-11-17",
      "subjectId": "sub-1",
      "sessionId": "ses-1",
      "status": "PRESENT",
      "createdAt": "2026-11-17T10:00:00.000Z",
      "updatedAt": "2026-11-17T10:00:00.000Z",
      "deletedAt": null
    }
  ],
  "legacyAttendance": [
    {
      "id": "leg-1",
      "date": "2026-11-16",
      "held": 4,
      "attended": 3,
      "createdAt": "2026-11-16T18:00:00.000Z",
      "updatedAt": "2026-11-16T18:00:00.000Z",
      "deletedAt": null
    }
  ],
  "notes": [
    {
      "id": "note-1",
      "content": "Assignment 2 due on Friday",
      "color": "rgba(16, 185, 129, 0.15)",
      "reminderDate": "2026-11-20T23:59:00.000Z",
      "createdAt": "2026-11-17T11:00:00.000Z"
    }
  ]
}
```

### Firebase Services in Use
1. **Firebase Authentication**: Google Auth provider + anonymous/guest token handling.
2. **Cloud Firestore**:
   - `users/{uid}`: Storing complete user attendance document with 5-second debounce.
   - `global/settings`: Storing global holidays, active semester templates, and announcements.
   - `leaderboard`: Storing opt-in anonymized scores.
3. **Firebase Cloud Messaging (FCM)**: Daily attendance reminders.

---

## 6. Flutter Baseline Status & Gap Analysis

| Component / Layer | Current Flutter State | Required Target (React 1:1 Parity) | Action Required |
| :--- | :--- | :--- | :--- |
| **Architecture** | Flat directory (`lib/{core, models, screens}`) | Feature-first clean modular structure | Refactor in Phase 1 |
| **Fonts** | Google Fonts `Inter` | Google Fonts **`Outfit`** | Update `AppTheme` in Phase 1 |
| **Theme Colors** | Default material blue seed | Exact dark `#050505` & light `#F8FAFC` tokens | Create `AppColors` in Phase 1 |
| **Data Schema** | Basic `Subject` with only counters | Full Schema V2 (`attendanceRecords`, `legacyAttendance`, `notes`) | Implement models in Phase 2 |
| **Local Storage** | Basic Hive `subjects_box` | Hive Box with TypeAdapters matching Schema V2 | Build in Phase 2 |
| **Firebase** | Missing (local mock only) | Firebase Auth, Cloud Firestore & FCM | Integrate in Phase 2 & 6 |
| **Navigation** | None (`home: DashboardScreen()`) | BottomNav (Home, Register, Leaderboard, Settings) + Drawer | Build Shell in Phase 3 |
| **Dashboard** | Simple list of cards | Exact Hero Ring + Stats list + Calendar Activity | Build in Phase 4 |
| **Register View** | None | Week/Month/All toggles + DayRow items | Build in Phase 4 |
| **Notes Screen** | None | Sticky Notes masonry grid + Markdown | Build in Phase 4 |
| **Leaderboard** | None | Real-time leaderboard table with badges | Build in Phase 4 |
| **Settings Screen**| None | Profile, Datalists, Backup Export/Import, Danger Zone | Build in Phase 4 |
| **Calculations** | Rough calculator without epsilon | Exact `attendance.js` port with float epsilon | Migrate in Phase 5 |

---

## 7. Migration Dependency Matrix (Flutter Packages)

To match React's capabilities cleanly and safely, the following packages are evaluated:

| Package | Purpose in Flutter | React Equivalent |
| :--- | :--- | :--- |
| `google_fonts: ^8.2.1` | **`Outfit` font family** | `@import url('https://fonts.googleapis.com/...Outfit')` |
| `hive_flutter: ^1.1.0` | Offline-first zero-latency storage | `localStorage` + IndexedDB |
| `firebase_core`, `firebase_auth`, `cloud_firestore` | Authentication & Cloud Sync | Firebase Web SDK 12.x |
| `flutter_riverpod: ^2.6.1` | Predictable reactive state management | React `AppContext.jsx` |
| `go_router: ^14.8.0` | Declarative routing & bottom bar shell | `react-router-dom` v7 |
| `intl: ^0.20.3` | Date formatting & calendar calculations | `date.js` |
| `flutter_markdown: ^0.7.6` | Sticky notes markdown rendering | `react-markdown` |
| `share_plus: ^13.3.1` | Native share dialog | `navigator.share` |
| `flutter_local_notifications` | Offline daily reminders at scheduled time | Web FCM Cron |

---

## 8. Risk Assessment & Mitigations

1. **Risk: Floating-Point Math Discrepancy**  
   *Mitigation*: Unit test Dart calculation functions directly against the 9 test cases in `react_app/tests/attendance.test.js`.
2. **Risk: Schema Compatibility on Cloud Sync**  
   *Mitigation*: Use defensive deserialization and retain `schemaVersion: 2` ensuring user data in Firestore is completely shared between Web and Mobile without schema corruption.
3. **Risk: UI Scale & Responsiveness**  
   *Mitigation*: Use LayoutBuilder and responsive tokens so cards and rings scale smoothly on all mobile viewports.

---

## 9. Conclusion & Phase 0 Sign-Off Request

Phase 0 discovery and audit is **100% complete**. No application source files have been prematurely altered.

### Recommended Next Step: Begin Phase 1 (Architecture Foundation)
Once approved, Phase 1 will establish:
- Clean modular folder architecture (`app/`, `core/`, `shared/`, `features/`).
- `AppColors.dart` with exact CSS hex and alpha values.
- `AppTheme.dart` using Google Fonts `Outfit`.
- `AppRouter.dart` with Bottom Navigation Bar shell matching `MobileLayout.jsx`.
- Riverpod state management foundation.

**Awaiting user approval to proceed to Phase 1.**
