# Remaining Tasks

## Phase 2: Firebase Integration
- Inspect `react_app/src/firebase.js`, `firestore.rules`, `react_app/.env.example`, and `SECURITY.md`.
- Add `firebase_core`, `firebase_auth`, `google_sign_in`, and `cloud_firestore` (plus `firebase_options.dart` via `flutterfire configure`).
- Implement real `FirebaseAuthRemoteDataSource` replacing `DefaultAuthRemoteDataSource` demo user (`google_user_demo_101`).
- Ensure persistent auth sessions and user-scoped Firestore access (`users/{uid}`).

## Phase 3: Cloud Synchronization
- Replace `DefaultRemoteSyncDataSource` (in-memory `Map`) with `FirestoreRemoteSyncDataSource` using Firestore transactions.
- Preserve Last-Write-Wins entity merge (`data_migration.dart`) for attendance, subjects, timetable, notes, and settings.
- Wire `globalSettingsProvider` to Firestore `settings/global` and pass global holidays into `calendar_providers.dart` and `DashboardPage`.
- Verify offline persistence, retry/error handling, and multi-instance sync.

## Phase 4: Leaderboard
- Replace hardcoded `_defaultCohort` in `LeaderboardRepositoryImpl` with live Firestore `leaderboard` collection + recalculation endpoint.
- Display real user identity, rank, attendance percentage, and streak with loading/error states.

## Phase 5: Admin Dashboard
- Recreate `react_app/src/components/AdminDashboard.jsx` in `flutter_app/lib/features/admin/`:
  - System health overview metrics.
  - User search and status filtering (`all`, `danger`, `safe`, `inactive`).
  - Global holiday management.
  - Program/semester configuration.
  - Push notification broadcast & direct user push (requires FCM + server-side validation).
- Gate Admin access via Firebase custom claim `admin == true` and add Admin button to `ProfileCard`.

## Phase 6: Final Testing & Cleanup
- Add integration tests covering real Firebase Auth, Firestore sync, leaderboard, and admin flows.
- Test offline/online transitions and backup/restore round-trips.
- Remove unused legacy prototype files (`lib/screens/dashboard_screen.dart`, `lib/models/subject.dart`).
