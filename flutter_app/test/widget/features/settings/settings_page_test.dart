import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/features/auth/domain/entities/auth_user_entity.dart';
import 'package:flutter_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_app/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:flutter_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter_app/features/settings/domain/models/backup_models.dart';
import 'package:flutter_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_app/features/settings/domain/services/backup_service.dart';
import 'package:flutter_app/features/settings/presentation/providers/settings_controller.dart';
import 'package:flutter_app/features/settings/presentation/settings_page.dart';
import 'package:flutter_app/features/settings/presentation/widgets/attendance_rules_card.dart';
import 'package:flutter_app/features/settings/presentation/widgets/backup_restore_card.dart';
import 'package:flutter_app/features/settings/presentation/widgets/danger_zone_card.dart';
import 'package:flutter_app/features/settings/presentation/widgets/notifications_card.dart';
import 'package:flutter_app/features/settings/presentation/widgets/personalization_card.dart';
import 'package:flutter_app/features/settings/presentation/widgets/profile_card.dart';

class _FakeAuthRepository implements AuthRepository {
  AuthUserEntity? user;
  bool onboarded = true;

  _FakeAuthRepository({this.user});

  @override
  Stream<AuthUserEntity?> watchAuthState() => const Stream.empty();

  @override
  AuthUserEntity? getCachedCurrentUser() => user;

  @override
  bool isCachedOnboardingComplete() => onboarded;

  @override
  Future<AuthUserEntity?> getCurrentUser() async => user;

  @override
  Future<AuthUserEntity> signInWithGoogle() async => const AuthUserEntity(
    id: 'u1',
    email: 'test@student.edu',
    displayName: 'Student User',
  );

  @override
  Future<AuthUserEntity> signInAsGuest() async => AuthUserEntity.guest();

  @override
  Future<void> signOut() async {
    user = null;
  }

  @override
  Future<bool> isOnboardingComplete() async => onboarded;

  @override
  Future<void> setOnboardingComplete(bool complete) async {
    onboarded = complete;
  }
}

class _FakeSettingsRepo extends Fake implements SettingsRepository {
  UserSettingsEntity settings;
  _FakeSettingsRepo(this.settings);

  @override
  Future<UserSettingsEntity> getSettings() async => settings;

  @override
  Stream<UserSettingsEntity> watchSettings() => Stream.value(settings);

  @override
  Future<void> saveSettings(UserSettingsEntity s) async {
    settings = s;
  }
}

class _FakeBackupService extends Fake implements BackupService {
  @override
  BackupParseResult parseBackup(dynamic input) =>
      const BackupParseResult(isValid: true);

  @override
  Future<BackupRestoreResult> restoreBackup(Map<String, dynamic> data) async =>
      const BackupRestoreResult(ok: true);

  @override
  Future<String> createBackupJsonString() async => '{}';

  @override
  Future<bool> resetAllAttendanceAndNotes() async => true;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const testSettings = UserSettingsEntity(
    name: 'Rahul Sharma',
    programName: 'Computer Science',
    courseName: 'B.Tech',
    startDate: '2026-08-01',
    minPercent: 75.0,
    classDays: [1, 2, 3, 4, 5],
    reminderTime: '18:00',
    pushNotificationsEnabled: true,
  );

  Widget createWidget({
    UserSettingsEntity settings = testSettings,
    AuthUserEntity? user = const AuthUserEntity(
      id: 'student_123',
      email: 'rahul@college.edu',
      displayName: 'Rahul Sharma',
    ),
  }) {
    final fakeAuth = _FakeAuthRepository(user: user);
    final fakeSettings = _FakeSettingsRepo(settings);
    final fakeBackup = _FakeBackupService();

    return ProviderScope(
      overrides: [
        settingsStreamProvider.overrideWith((ref) => Stream.value(settings)),
        settingsRepositoryProvider.overrideWithValue(fakeSettings),
        backupServiceProvider.overrideWithValue(fakeBackup),
        authRepositoryProvider.overrideWithValue(fakeAuth),
        authNotifierProvider.overrideWith((ref) => AuthNotifier(fakeAuth)),
      ],
      child: const MaterialApp(home: Scaffold(body: SettingsPage())),
    );
  }

  group('SettingsPage Widget Tests', () {
    testWidgets('Renders all 6 core settings cards', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ProfileCard), findsOneWidget);
      expect(find.byType(PersonalizationCard), findsOneWidget);
      expect(find.byType(AttendanceRulesCard), findsOneWidget);
      expect(find.byType(NotificationsCard), findsOneWidget);
      expect(find.byType(BackupRestoreCard), findsOneWidget);
      expect(find.byType(DangerZoneCard), findsOneWidget);
    });

    testWidgets('ProfileCard displays user display name and email', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Rahul Sharma'), findsWidgets);
      expect(find.text('rahul@college.edu'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('ProfileCard displays guest info when user is not logged in', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createWidget(settings: const UserSettingsEntity(name: ''), user: null),
      );
      await tester.pumpAndSettle();

      expect(find.text('Guest User'), findsOneWidget);
      expect(
        find.text('Not logged in — stored on this device only'),
        findsOneWidget,
      );
    });

    testWidgets('PersonalizationCard displays form labels and initial values', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Personalization'), findsOneWidget);
      expect(find.text('Your Name'), findsOneWidget);
      expect(find.text('Degree / Program name'), findsOneWidget);
      expect(find.text('Semester name'), findsOneWidget);
    });

    testWidgets(
      'AttendanceRulesCard displays minimum criteria and class days',
      (tester) async {
        tester.view.physicalSize = const Size(400, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Attendance Rules'), findsOneWidget);
        expect(find.text('MINIMUM ATTENDANCE REQUIRED'), findsOneWidget);
        expect(find.text('WHICH DAYS DO YOU HAVE CLASS?'), findsOneWidget);
      },
    );

    testWidgets('BackupRestoreCard renders Export and Choose Backup buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Backup & Restore'), findsOneWidget);
      expect(find.text('Export full backup'), findsOneWidget);
      expect(find.text('Choose backup to restore'), findsOneWidget);
    });

    testWidgets(
      'DangerZoneCard renders Clear attendance history and triggers confirm dialog',
      (tester) async {
        tester.view.physicalSize = const Size(400, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text('Danger Zone'), findsOneWidget);
        final clearBtn = find.text('Clear attendance history');
        expect(clearBtn, findsOneWidget);

        await tester.tap(clearBtn);
        await tester.pumpAndSettle();

        // Verify confirmation dialog opened
        expect(find.text('Clear Attendance History?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Clear History'), findsOneWidget);

        // Dismiss dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Clear Attendance History?'), findsNothing);
      },
    );

    testWidgets(
      'Renders cleanly on compact 320x568 mobile viewport without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Profile'), findsOneWidget);

        // Scroll through the entire page
        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Danger Zone'), findsOneWidget);
      },
    );
  });
}
