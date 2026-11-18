import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/features/auth/domain/entities/auth_user_entity.dart';
import 'package:flutter_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_app/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:flutter_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:flutter_app/features/auth/presentation/controllers/auth_state.dart';
import 'package:flutter_app/features/auth/presentation/pages/auth_page.dart';

class MockAuthRepository implements AuthRepository {
  bool googleSignInCalled = false;
  bool guestSignInCalled = false;

  @override
  Stream<AuthUserEntity?> watchAuthState() => const Stream.empty();

  @override
  AuthUserEntity? getCachedCurrentUser() => null;

  @override
  bool isCachedOnboardingComplete() => false;

  @override
  Future<AuthUserEntity?> getCurrentUser() async => null;

  @override
  Future<AuthUserEntity> signInWithGoogle() async {
    googleSignInCalled = true;
    return const AuthUserEntity(id: 'google_test', displayName: 'Google Tester');
  }

  @override
  Future<AuthUserEntity> signInAsGuest() async {
    guestSignInCalled = true;
    return AuthUserEntity.guest();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> isOnboardingComplete() async => false;

  @override
  Future<void> setOnboardingComplete(bool complete) async {}
}

class TestLoadingNotifier extends AuthNotifier {
  TestLoadingNotifier(super.repo) {
    state = const AuthState(status: AuthStatus.loading);
  }

  @override
  Future<void> init() async {
    state = const AuthState(status: AuthStatus.loading);
  }
}

class TestErrorNotifier extends AuthNotifier {
  final String errorMsg;

  TestErrorNotifier(super.repo, this.errorMsg) {
    state = AuthState(status: AuthStatus.error, errorMessage: errorMsg);
  }

  @override
  Future<void> init() async {
    state = AuthState(status: AuthStatus.error, errorMessage: errorMsg);
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AuthPage Widget Tests', () {
    testWidgets('Renders title, subtitle, Google button, and Guest button', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: AuthPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Attendance Tracker'), findsOneWidget);
      expect(find.text('Sign in to track your attendance'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Skip for now (Use as Guest)'), findsOneWidget);
    });

    testWidgets('Tapping Continue with Google triggers signInWithGoogle', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: AuthPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(mockRepo.googleSignInCalled, isTrue);
    });

    testWidgets('Tapping Skip for now (Use as Guest) triggers signInAsGuest', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: AuthPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip for now (Use as Guest)'));
      await tester.pumpAndSettle();

      expect(mockRepo.guestSignInCalled, isTrue);
    });

    testWidgets('Displays error banner when auth state has error message', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith(
              (ref) => TestErrorNotifier(mockRepo, 'Authentication failed: network timeout'),
            ),
          ],
          child: const MaterialApp(
            home: AuthPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Authentication failed: network timeout'), findsOneWidget);
    });

    testWidgets('Displays Connecting... when loading state is active', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
            authNotifierProvider.overrideWith((ref) => TestLoadingNotifier(mockRepo)),
          ],
          child: const MaterialApp(
            home: AuthPage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Connecting...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
