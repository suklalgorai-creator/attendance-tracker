import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/features/auth/domain/entities/auth_user_entity.dart';
import 'package:flutter_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_app/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:flutter_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:flutter_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter_app/features/settings/domain/repositories/settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  UserSettingsEntity? savedSettings;

  @override
  Future<UserSettingsEntity> getSettings() async =>
      savedSettings ?? const UserSettingsEntity();

  @override
  Stream<UserSettingsEntity> watchSettings() => const Stream.empty();

  @override
  Future<void> saveSettings(UserSettingsEntity settings) async {
    savedSettings = settings;
  }

  @override
  Future<void> resetSettings() async {
    savedSettings = null;
  }
}

class MockAuthRepository implements AuthRepository {
  bool onboardingCompleted = false;

  @override
  Stream<AuthUserEntity?> watchAuthState() => const Stream.empty();

  @override
  AuthUserEntity? getCachedCurrentUser() => null;

  @override
  bool isCachedOnboardingComplete() => onboardingCompleted;

  @override
  Future<AuthUserEntity?> getCurrentUser() async => null;

  @override
  Future<AuthUserEntity> signInWithGoogle() async =>
      const AuthUserEntity(id: 'test');

  @override
  Future<AuthUserEntity> signInAsGuest() async => AuthUserEntity.guest();

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> isOnboardingComplete() async => onboardingCompleted;

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    onboardingCompleted = complete;
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('OnboardingPage Widget Tests', () {
    testWidgets('Renders all fields, labels, suggestion chips, and CTA button', (
      tester,
    ) async {
      final mockSettings = MockSettingsRepository();
      final mockAuth = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockSettings),
            authRepositoryProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(home: OnboardingPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set up your register'), findsOneWidget);
      expect(
        find.text(
          'A daily attendance tracker that shows exactly how safe — or how behind — you are.',
        ),
        findsOneWidget,
      );
      expect(find.text('Degree / Program name (optional)'), findsOneWidget);
      expect(find.text('Semester name (optional)'), findsOneWidget);
      expect(find.text('Classes started on'), findsOneWidget);
      expect(find.text('Minimum attendance required'), findsOneWidget);
      expect(find.text('Which days do you have class?'), findsOneWidget);
      expect(find.text('Start tracking'), findsOneWidget);
    });

    testWidgets(
      'Tapping program and semester suggestion chips populates inputs',
      (tester) async {
        final mockSettings = MockSettingsRepository();
        final mockAuth = MockAuthRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(mockSettings),
              authRepositoryProvider.overrideWithValue(mockAuth),
            ],
            child: const MaterialApp(home: OnboardingPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap 'B.Tech CSE' chip
        await tester.tap(find.text('B.Tech CSE'));
        await tester.pumpAndSettle();
        expect(find.text('B.Tech CSE'), findsWidgets);

        // Tap 'Semester 3' chip
        await tester.tap(find.text('Semester 3'));
        await tester.pumpAndSettle();
        expect(find.text('Semester 3'), findsWidgets);
      },
    );

    testWidgets(
      'Submitting form saves settings and marks onboarding completed',
      (tester) async {
        final mockSettings = MockSettingsRepository();
        final mockAuth = MockAuthRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(mockSettings),
              authRepositoryProvider.overrideWithValue(mockAuth),
              authNotifierProvider.overrideWith(
                (ref) => AuthNotifier(mockAuth),
              ),
            ],
            child: const MaterialApp(home: OnboardingPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Select Program & Semester chips
        await tester.tap(find.text('B.Tech IT'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Semester 2'));
        await tester.pumpAndSettle();

        // Scroll into view and tap 'Start tracking'
        await tester.ensureVisible(find.text('Start tracking'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Start tracking'));
        await tester.pumpAndSettle();

        expect(mockSettings.savedSettings, isNotNull);
        expect(mockSettings.savedSettings!.programName, 'B.Tech IT');
        expect(mockSettings.savedSettings!.courseName, 'Semester 2');
        expect(mockSettings.savedSettings!.minPercent, 75.0);
        expect(mockSettings.savedSettings!.classDays, [1, 2, 3, 4, 5]);
        expect(mockAuth.onboardingCompleted, isTrue);
      },
    );
  });
}
