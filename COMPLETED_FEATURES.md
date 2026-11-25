# Completed Features

## Pre-Existing Local-First Features (Verified)
- **Theme & Design System:** Dark/Light theme (`AppTheme`, `AppColors`, `AppTypography` with `Outfit`), `GlassCard`, mesh backdrop.
- **Navigation Shell:** `GoRouter` with `StatefulShellRoute.indexedStack`, mobile bottom navigation, responsive desktop collapsible sidebar (`AppShell`), and `AppDrawer`.
- **Onboarding Wizard:** Program, semester, start date, minimum attendance %, and class days persisted to Hive (`OnboardingPage`).
- **Dashboard & Math Engine:** `AttendanceCalculator` (IEEE-754 `1e-10` epsilon parity with React), `AttendanceRing`, `AdvisorBanner`, `TodaysScheduleCard`, `QuickActionSubjectCard` with Undo snackbar.
- **Activity Card:** Monthly `CalendarViewWidget` and 26-week `HeatmapView`.
- **Session Register:** Week / Month / All range toggles and `DayRow` daily attendance marking (`RegisterPage`).
- **Subjects & Timetable (Beyond React):** Subject CRUD (`SubjectDialog`), `SubjectAnalyticsScreen`, and `TimetablePage` / `TimetableEditor`.
- **Settings, Backup & Reset:** Profile, Personalization, Attendance Rules, JSON Backup/Restore (5 MB guard + pre-restore safety backup), CSV Export, and Danger Zone reset.

## Newly Completed in Phase 1
- **Local Notifications Wiring:** `notificationServiceProvider` now uses `FlutterLocalNotificationServiceImpl` and `AppShell` watches `notificationSchedulerProvider` (`notification_providers.dart`, `app_shell.dart`).
- **Note Reminder Scheduling:** `NotificationService` supports `scheduleNoteReminder` and `cancelNoteReminder`, wired to `NotesPage` save/delete flows (`notification_service.dart`, `notes_page.dart`).
- **Header Streak Popup:** Tapping the streak pill in `AppHeader` opens `StreakPopupDialog` (`app_header.dart`).
- **Sticky Notes Markdown, Encoding & Date/Time Picker:** Real Markdown rendering via `flutter_markdown_plus`, clean `⏰` icon, and combined date + time reminder selection (`notes_page.dart`).
- **Drawer Feedback Action:** "Send Feedback" launches `mailto:codecraftdigital.in@gmail.com?subject=Attendance App Feedback` via `url_launcher` with snackbar fallback (`app_drawer.dart`).
- **Accessibility Preservation:** Removed `accessibleNavigation: false` override in `AttendanceApp` (`app.dart`).
