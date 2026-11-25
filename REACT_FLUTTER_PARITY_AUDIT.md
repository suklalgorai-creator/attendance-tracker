# React → Flutter UI/UX Parity Audit

Date: 2026-11-24

Source of truth: `react_app/`

Target: `flutter_app/`

## Scope and baseline

The React source was reviewed across its routes, layouts, pages, components, styles, data model, cloud-sync service, and authentication flow. The Flutter source was reviewed across its router, shell, design tokens, feature pages, repositories, providers, and reusable widgets. Existing automated tests and build/analyze commands were also checked before implementation.

The worktree already contained a user change in `flutter_app/pubspec.lock`; it is preserved.

React exposes these user-facing flows:

- Authentication and guest mode
- First-run onboarding
- Dashboard with attendance hero, advisor, activity calendar/heatmap, schedule, streak, and quick subject actions
- Session register with week/month/all ranges and daily editing
- Leaderboard
- Sticky Notes CRUD with reminders, colors, markdown rendering, and delete confirmation
- Settings with profile, theme, attendance rules, notifications, backup/restore, and danger zone
- Timetable editor and subject analytics as supporting flows
- Desktop sidebar and mobile bottom navigation
- Firebase Auth, Firestore synchronization, FCM notification support, local persistence, and CSV/JSON backup actions

Flutter currently contains corresponding feature folders for most of these flows and has centralized color, typography, spacing, radius, theme, and reusable-widget resources. Its data layer is substantially more complete than the earlier audit in `AUDIT_REPORT.md` suggests, but several parity gaps remain.

## Design-system comparison

| Area | React | Flutter | Finding |
| --- | --- | --- | --- |
| Font | Outfit, weights 300–800 | Google Fonts Outfit | Matched in the shared theme/tokens |
| Dark background | `#050505` | `AppColors.bgPrimaryDark` | Matched |
| Light background | `#F8FAFC` | `AppColors.bgPrimaryLight` | Matched |
| Surfaces and borders | translucent zinc/white glass tokens | centralized `AppColors` tokens | Mostly matched |
| Accents | emerald, rose, amber | centralized accent tokens | Matched |
| Background mesh | three animated blurred CSS orbs, simplified on mobile | no equivalent app-wide background layer | Missing |
| Responsive shell | desktop sidebar at 1024px+, mobile bottom nav | one `Scaffold` with bottom nav and drawer | Major mismatch |
| Header content | live program/course labels and streak | `AppHeader` supports values but `AppShell` does not pass them | Functional/visual mismatch |
| Card language | glass surface, 16px radius, subtle borders/shadows | shared `GlassCard` plus feature-specific containers | Mostly matched, but not uniformly applied |

## Screen and interaction comparison

| Flow | React behavior | Flutter behavior | Priority |
| --- | --- | --- | --- |
| Auth | Firebase Google popup, guest mode, real error state | offline deterministic Google demo user, guest mode | High functional parity gap |
| Onboarding | program/semester datalists, date, target, class days | equivalent fields plus chips and native pickers | Minor visual/interaction refinement |
| Dashboard | source layout includes hero/register/stats/activity ordering | feature-rich dashboard exists, but app shell/header context is incomplete | High visual parity |
| Register | range toggles, known dates, class-day history, global holiday labels | range toggles and daily editor exist; `isHoliday` is hardcoded `false` | High functional gap |
| Notes | masonry CRUD, edit modal, color, reminder date, markdown, delete confirmation, FAB | placeholder page with static copy only | Critical feature gap |
| Settings | all settings and backup/restore controls | feature cards and backup service exist | Mostly implemented; needs parity polish and platform validation |
| Leaderboard | remote Firestore ranking and current-user state | local/provider-backed ranking UI | High integration gap |
| Drawer | CSV export, install, theme, what's new, share, support, feedback | navigation/theme/share/dialogs; CSV is a placeholder snackbar and install/feedback are absent | High functional gap |
| Timetable | weekly session editor | route and editor exist | Minor validation needed |
| Subject analytics | dashboard-linked detail flow | route and screen exist | Minor validation needed |
| Admin | lazy-loaded admin dashboard for authorized users | no equivalent Flutter route/flow found | High feature gap for admin users |

## Functional architecture comparison

React uses Firebase Auth, Firestore transactions with local persistence, FCM token handling, and browser local storage. Flutter has Hive repositories, backup/restore, notification abstractions, and sync service contracts, but the default auth and remote sync implementations are explicitly offline/in-memory adapters:

- `DefaultAuthRemoteDataSource.signInWithGoogle()` returns a fixed demo user.
- `DefaultRemoteSyncDataSource` stores remote data in an in-memory map.
- Notification service uses a simulated FCM token fallback.

These adapters are useful for deterministic tests and offline development, but they are not production-equivalent to the React Firebase integrations. Completing native Firebase parity requires project configuration and platform credentials that are not present in the current Flutter project, so it is tracked as an integration task rather than silently replacing the existing adapters.

## Baseline validation

- React `npm test` and `npm run build` were attempted. Both were stopped by Windows `spawn EPERM` from the Node/esbuild process before application tests/building ran.
- The initial Flutter CLI attempts did not produce output within the command window. After running the Dart analyzer with the required process permission, Flutter analysis completed with `No issues found`.
- Static source review found no need to rewrite the existing repositories or business rules for the UI parity pass.

## Post-implementation validation

- Dart analyzer: passed with no issues.
- `test/widget/app_router_test.dart`: 9 tests passed.
- `test/widget/features/settings/settings_page_test.dart`: 8 tests passed.
- `test/widget/e2e/viewport_regression_test.dart`: 4 tests passed, including 320px dashboard, register, leaderboard, and settings layouts.
- The full Flutter suite exceeded the 120-second command timeout without producing a final result, so it is not reported as passed.

## Implementation order

1. Make the shell responsive and pass live header context, preserving existing routes/providers.
2. Add the shared React-like mesh background and tighten common shell styling.
3. Replace the Notes placeholder with repository-backed CRUD UI.
4. Make CSV export real and add holiday propagation to Register.
5. Re-run source-level checks and document unresolved Firebase/admin integration gaps.
