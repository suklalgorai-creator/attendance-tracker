import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/app/app.dart';
import 'package:flutter_app/app/router/app_router.dart';
import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/features/auth/domain/entities/auth_user_entity.dart';
import 'package:flutter_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_app/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:flutter_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:flutter_app/features/dailyflow/presentation/widgets/daily_flow_dashboard_card.dart';

class RouterTestAuthRepository implements AuthRepository {
  AuthUserEntity? user;
  bool onboarded = false;

  RouterTestAuthRepository({this.user, this.onboarded = false});

  @override
  Stream<AuthUserEntity?> watchAuthState() => const Stream.empty();

  @override
  AuthUserEntity? getCachedCurrentUser() => user;

  @override
  bool isCachedOnboardingComplete() => onboarded;

  @override
  Future<AuthUserEntity?> getCurrentUser() async => user;

  @override
  Future<AuthUserEntity> signInWithGoogle() async {
    const u = AuthUserEntity(id: 'google_user', displayName: 'Google User');
    user = u;
    return u;
  }

  @override
  Future<AuthUserEntity> signInAsGuest() async {
    final g = AuthUserEntity.guest();
    user = g;
    return g;
  }

  @override
  Future<void> signOut() async {
    user = null;
    onboarded = false;
  }

  @override
  Future<bool> isOnboardingComplete() async => onboarded;

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    onboarded = complete;
  }
}

void main() {
  setUpAll(() {
    // Disable runtime font fetching to keep widget tests deterministic & offline
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppRouter Auth Gating & Shell Navigation Widget Tests', () {
    testWidgets('Unauthenticated user is redirected to /auth', (tester) async {
      final mockRepo = RouterTestAuthRepository(user: null, onboarded: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            showSplashProvider.overrideWithValue(false),
            authRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith((ref) => AuthNotifier(mockRepo)),
          ],
          child: const AttendanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Displays AuthPage
      expect(find.text('Attendance Tracker'), findsOneWidget);
      expect(find.text('Sign in to track your attendance'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Skip for now (Use as Guest)'), findsOneWidget);
    });

    testWidgets(
      'Authenticated or guest user with incomplete onboarding is redirected to /onboarding',
      (tester) async {
        final mockRepo = RouterTestAuthRepository(
          user: AuthUserEntity.guest(),
          onboarded: false,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              showSplashProvider.overrideWithValue(false),
              authRepositoryProvider.overrideWithValue(mockRepo),
              authNotifierProvider.overrideWith(
                (ref) => AuthNotifier(mockRepo),
              ),
            ],
            child: const AttendanceApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Displays OnboardingPage
        expect(find.text('Set up your register'), findsOneWidget);
        expect(find.text('Start tracking'), findsOneWidget);
      },
    );

    testWidgets(
      'Onboarded authenticated user accesses DashboardPage and AppShell',
      (tester) async {
        final mockRepo = RouterTestAuthRepository(
          user: const AuthUserEntity(id: 'student_1', displayName: 'Student'),
          onboarded: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              showSplashProvider.overrideWithValue(false),
              authRepositoryProvider.overrideWithValue(mockRepo),
              authNotifierProvider.overrideWith(
                (ref) => AuthNotifier(mockRepo),
              ),
            ],
            child: const AttendanceApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('My Attendance'), findsOneWidget);
        expect(find.byType(DailyFlowDashboardCard), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Register'), findsOneWidget);
        expect(find.text('DailyFlow'), findsWidgets);
        expect(find.text('Leaderboard'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
        // No guest warning banner for authenticated Google user
        expect(find.textContaining('Data not backed up!'), findsNothing);
      },
    );

    testWidgets(
      'AppShell bottom navigation bar renders cleanly on compact viewport Size(320, 568)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockRepo = RouterTestAuthRepository(
          user: const AuthUserEntity(id: 'student_1', displayName: 'Student'),
          onboarded: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              showSplashProvider.overrideWithValue(false),
              authRepositoryProvider.overrideWithValue(mockRepo),
              authNotifierProvider.overrideWith(
                (ref) => AuthNotifier(mockRepo),
              ),
            ],
            child: const AttendanceApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Register'), findsOneWidget);
        expect(find.text('DailyFlow'), findsWidgets);
        expect(find.text('Leaderboard'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'Guest mode renders top Amber warning banner in AppShell and tapping signs out',
      (tester) async {
        final mockRepo = RouterTestAuthRepository(
          user: AuthUserEntity.guest(),
          onboarded: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              showSplashProvider.overrideWithValue(false),
              authRepositoryProvider.overrideWithValue(mockRepo),
              authNotifierProvider.overrideWith(
                (ref) => AuthNotifier(mockRepo),
              ),
            ],
            child: const AttendanceApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Guest banner is visible in shell
        expect(
          find.text(
            '⚠️ Data not backed up! Tap here to Sign in and save your attendance in the cloud.',
          ),
          findsOneWidget,
        );

        // Tapping the banner triggers sign out and redirects to /auth
        await tester.tap(
          find.text(
            '⚠️ Data not backed up! Tap here to Sign in and save your attendance in the cloud.',
          ),
        );
        await tester.pumpAndSettle();

        // User is redirected to AuthPage
        expect(find.text('Attendance Tracker'), findsOneWidget);
        expect(find.text('Sign in to track your attendance'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping bottom tabs switches branches preserving state for onboarded user',
      (tester) async {
        final mockRepo = RouterTestAuthRepository(
          user: const AuthUserEntity(id: 'student_1', displayName: 'Student'),
          onboarded: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              showSplashProvider.overrideWithValue(false),
              authRepositoryProvider.overrideWithValue(mockRepo),
              authNotifierProvider.overrideWith(
                (ref) => AuthNotifier(mockRepo),
              ),
            ],
            child: const AttendanceApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Register Tab
        await tester.tap(find.text('Register'));
        await tester.pumpAndSettle();
        expect(find.text('Session Register'), findsOneWidget);

        // Tap DailyFlow Tab
        await tester.tap(find.text('DailyFlow'));
        await tester.pumpAndSettle();
        expect(find.text('Add a task...'), findsOneWidget);

        // Tap Leaderboard Tab
        await tester.tap(find.byIcon(Icons.emoji_events_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Attendance Leaderboard'), findsOneWidget);

        // Tap Profile Tab
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('ACCOUNT & PROFILE'), findsOneWidget);

        // Return to Home Tab
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        expect(find.byType(DailyFlowDashboardCard), findsOneWidget);
      },
    );

    testWidgets('Opening Drawer and selecting Sticky Notes pushes /notes', (
      tester,
    ) async {
      final mockRepo = RouterTestAuthRepository(
        user: const AuthUserEntity(id: 'student_1', displayName: 'Student'),
        onboarded: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            showSplashProvider.overrideWithValue(false),
            authRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith((ref) => AuthNotifier(mockRepo)),
          ],
          child: const AttendanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap hamburger menu button
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Sticky Notes'), findsOneWidget);

      // Tap Sticky Notes item
      await tester.tap(find.text('Sticky Notes'));
      await tester.pumpAndSettle();

      expect(find.text('Sticky Notes Page'), findsOneWidget);
    });

    testWidgets('Header theme toggle reacts immediately in MaterialApp', (
      tester,
    ) async {
      final mockRepo = RouterTestAuthRepository(
        user: const AuthUserEntity(id: 'student_1', displayName: 'Student'),
        onboarded: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            showSplashProvider.overrideWithValue(false),
            authRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith((ref) => AuthNotifier(mockRepo)),
          ],
          child: const AttendanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Default is dark mode -> header displays sun emoji to switch to light
      expect(find.text('☀️'), findsOneWidget);

      // Tap theme switch button
      await tester.tap(find.text('☀️'));
      await tester.pumpAndSettle();

      // State switches to light mode -> header displays moon emoji to switch to dark
      expect(find.text('🌙'), findsOneWidget);
    });

    testWidgets(
      'Navigating to /subject/:id renders SubjectAnalyticsScreen (Not Found for missing ID)',
      (tester) async {
        final mockRepo = RouterTestAuthRepository(
          user: const AuthUserEntity(id: 'student_1', displayName: 'Student'),
          onboarded: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              showSplashProvider.overrideWithValue(false),
              authRepositoryProvider.overrideWithValue(mockRepo),
              authNotifierProvider.overrideWith(
                (ref) => AuthNotifier(mockRepo),
              ),
              subjectsStreamProvider.overrideWith((ref) => Stream.value([])),
              attendanceRecordsStreamProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
            ],
            child: const AttendanceApp(),
          ),
        );
        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(AttendanceApp)),
        );
        container.read(appRouterProvider).push('/subject/sub_missing_999');
        await tester.pumpAndSettle();

        expect(find.text('Subject Not Found'), findsOneWidget);
        expect(find.byKey(const Key('not_found_back_button')), findsOneWidget);

        // Tapping Return to Dashboard pops back to DashboardPage
        await tester.tap(find.byKey(const Key('not_found_back_button')));
        await tester.pumpAndSettle();

        expect(find.byType(DailyFlowDashboardCard), findsOneWidget);
      },
    );
  });
}
