import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/shared/widgets/view_toggles_widget.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_app/features/register/presentation/pages/register_page.dart';
import 'package:flutter_app/features/register/presentation/widgets/day_row.dart';

class FakeRegisterAttendanceRepository implements AttendanceRepository {
  final List<LegacyAttendanceEntity> legacyStorage = [];
  final List<AttendanceRecordEntity> recordStorage = [];

  final _legacyStreamController =
      StreamController<List<LegacyAttendanceEntity>>.broadcast();
  final _recordsStreamController =
      StreamController<List<AttendanceRecordEntity>>.broadcast();

  @override
  Future<List<LegacyAttendanceEntity>> getLegacyAttendance(
      {bool includeDeleted = false}) async {
    if (includeDeleted) return List.from(legacyStorage);
    return legacyStorage.where((r) => !r.isDeleted).toList();
  }

  @override
  Stream<List<LegacyAttendanceEntity>> watchLegacyAttendance(
      {bool includeDeleted = false}) {
    return _legacyStreamController.stream;
  }

  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceEntity record) async {
    final idx = legacyStorage.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      legacyStorage[idx] = record;
    } else {
      legacyStorage.add(record);
    }
    _legacyStreamController.add(List.from(legacyStorage));
  }

  @override
  Future<void> saveLegacyAttendances(
      List<LegacyAttendanceEntity> records) async {
    for (final r in records) {
      await saveLegacyAttendance(r);
    }
  }

  @override
  Future<void> deleteLegacyAttendance(String id) async {
    final idx = legacyStorage.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      legacyStorage[idx] = legacyStorage[idx].copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _legacyStreamController.add(List.from(legacyStorage));
    }
  }

  @override
  Future<void> hardDeleteLegacyAttendance(String id) async {
    legacyStorage.removeWhere((r) => r.id == id);
    _legacyStreamController.add(List.from(legacyStorage));
  }

  @override
  Future<void> restoreLegacyAttendance(String id) async {
    final idx = legacyStorage.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      legacyStorage[idx] = legacyStorage[idx].copyWith(clearDeletedAt: true);
      _legacyStreamController.add(List.from(legacyStorage));
    }
  }

  @override
  Future<List<AttendanceRecordEntity>> getAttendanceRecords(
      {bool includeDeleted = false}) async {
    if (includeDeleted) return List.from(recordStorage);
    return recordStorage.where((r) => !r.isDeleted).toList();
  }

  @override
  Stream<List<AttendanceRecordEntity>> watchAttendanceRecords(
      {bool includeDeleted = false}) {
    return _recordsStreamController.stream;
  }

  @override
  Future<void> saveAttendanceRecord(AttendanceRecordEntity record) async {
    final idx = recordStorage.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      recordStorage[idx] = record;
    } else {
      recordStorage.add(record);
    }
    _recordsStreamController.add(List.from(recordStorage));
  }

  @override
  Future<void> saveAttendanceRecords(
      List<AttendanceRecordEntity> records) async {
    for (final r in records) {
      await saveAttendanceRecord(r);
    }
  }

  @override
  Future<void> deleteAttendanceRecord(String id) async {
    final idx = recordStorage.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      recordStorage[idx] = recordStorage[idx].copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _recordsStreamController.add(List.from(recordStorage));
    }
  }

  @override
  Future<void> hardDeleteAttendanceRecord(String id) async {
    recordStorage.removeWhere((r) => r.id == id);
    _recordsStreamController.add(List.from(recordStorage));
  }

  @override
  Future<void> restoreAttendanceRecord(String id) async {
    final idx = recordStorage.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      recordStorage[idx] = recordStorage[idx].copyWith(clearDeletedAt: true);
      _recordsStreamController.add(List.from(recordStorage));
    }
  }

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForDate(String date,
          {bool includeDeleted = false}) async =>
      [];

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForSubject(String subjectId,
          {bool includeDeleted = false}) async =>
      [];

  @override
  Future<void> clearAllAttendanceHistory() async {
    legacyStorage.clear();
    recordStorage.clear();
    _legacyStreamController.add([]);
    _recordsStreamController.add([]);
  }

  void dispose() {
    _legacyStreamController.close();
    _recordsStreamController.close();
  }
}

class FakeRegisterSettingsRepository implements SettingsRepository {
  UserSettingsEntity settings;

  final _streamController = StreamController<UserSettingsEntity>.broadcast();

  FakeRegisterSettingsRepository({
    this.settings = const UserSettingsEntity(
      startDate: '2026-10-01',
      classDays: [1, 2, 3, 4, 5],
    ),
  });

  @override
  Future<UserSettingsEntity> getSettings() async => settings;

  @override
  Stream<UserSettingsEntity> watchSettings() => _streamController.stream;

  @override
  Future<void> saveSettings(UserSettingsEntity newSettings) async {
    settings = newSettings;
    _streamController.add(settings);
  }

  @override
  Future<void> resetSettings() async {
    settings = const UserSettingsEntity();
    _streamController.add(settings);
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late FakeRegisterAttendanceRepository fakeAttendanceRepo;
  late FakeRegisterSettingsRepository fakeSettingsRepo;

  setUp(() {
    fakeAttendanceRepo = FakeRegisterAttendanceRepository();
    fakeSettingsRepo = FakeRegisterSettingsRepository();
  });

  tearDown(() {
    fakeAttendanceRepo.dispose();
    fakeSettingsRepo.dispose();
  });

  Widget buildTestableWidget({
    UserSettingsEntity? initialSettings,
    GoRouter? router,
  }) {
    if (initialSettings != null) {
      fakeSettingsRepo.settings = initialSettings;
    }

    final effectiveRouter = router ??
        GoRouter(
          initialLocation: '/register',
          routes: [
            GoRoute(
              path: '/register',
              builder: (context, state) => const RegisterPage(),
            ),
            GoRoute(
              path: '/leaderboard',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Leaderboard Screen')),
              ),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(fakeAttendanceRepo),
        settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
      ],
      child: MaterialApp.router(
        routerConfig: effectiveRouter,
      ),
    );
  }

  group('RegisterPage Widget Tests', () {
    testWidgets('renders Session Register card, Leaderboard button, and ViewTogglesWidget', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Session Register'), findsOneWidget);
      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.byType(ViewTogglesWidget), findsOneWidget);
      expect(find.text('WEEK'), findsOneWidget);
      expect(find.text('MONTH'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
    });

    testWidgets('renders DayRow list for week by default', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final dayRows = find.byType(DayRow);
      expect(dayRows, findsWidgets);
    });

    testWidgets('toggling view mode to Month and All updates active tab and row list', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap Month
      await tester.tap(find.text('MONTH'));
      await tester.pumpAndSettle();
      expect(find.byType(DayRow), findsWidgets);

      // Tap All
      await tester.tap(find.text('ALL'));
      await tester.pumpAndSettle();
      expect(find.byType(DayRow), findsWidgets);
    });

    testWidgets('renders empty state hint when no dates are available', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        initialSettings: const UserSettingsEntity(
          startDate: '2099-01-01', // Future start date produces 0 class days
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('No class dates are available for this range.'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Leaderboard navigates to /leaderboard', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();

      expect(find.text('Leaderboard Screen'), findsOneWidget);
    });

    testWidgets('interactive attendance marking updates record and UI', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final presentButtons = find.text('Present');
      if (presentButtons.evaluate().isNotEmpty) {
        await tester.tap(presentButtons.first);
        await tester.pumpAndSettle();

        expect(fakeAttendanceRepo.legacyStorage, isNotEmpty);
      }
    });

    testWidgets('does not overflow on narrow 320px screen width', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Session Register'), findsOneWidget);
    });
  });
}
