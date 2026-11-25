import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:flutter_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/advisor_banner.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/empty_dashboard_view.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/overview_card.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/quick_action_subject_card.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/streak_badge.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';

class FakeAttendanceRepo implements AttendanceRepository {
  final List<AttendanceRecordEntity> saved = [];
  final List<String> deleted = [];
  final StreamController<List<AttendanceRecordEntity>> recordsController =
      StreamController<List<AttendanceRecordEntity>>.broadcast();

  @override
  Future<void> saveAttendanceRecord(AttendanceRecordEntity record) async {
    saved.add(record);
    recordsController.add(List.from(saved));
  }

  @override
  Future<void> deleteAttendanceRecord(String id) async {
    deleted.add(id);
    saved.removeWhere((r) => r.id == id);
    recordsController.add(List.from(saved));
  }

  @override
  Stream<List<AttendanceRecordEntity>> watchAttendanceRecords({
    bool includeDeleted = false,
  }) {
    return recordsController.stream;
  }

  @override
  Future<void> clearAllAttendanceHistory() async => saved.clear();

  @override
  Future<void> deleteLegacyAttendance(String id) async {}

  @override
  Future<List<AttendanceRecordEntity>> getAttendanceRecords({
    bool includeDeleted = false,
  }) async => List.from(saved);

  @override
  Future<List<LegacyAttendanceEntity>> getLegacyAttendance({
    bool includeDeleted = false,
  }) async => [];

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForDate(
    String date, {
    bool includeDeleted = false,
  }) async => [];

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForSubject(
    String subjectId, {
    bool includeDeleted = false,
  }) async => [];

  @override
  Future<void> hardDeleteAttendanceRecord(String id) async {}

  @override
  Future<void> hardDeleteLegacyAttendance(String id) async {}

  @override
  Future<void> restoreAttendanceRecord(String id) async {}

  @override
  Future<void> restoreLegacyAttendance(String id) async {}

  @override
  Future<void> saveAttendanceRecords(
    List<AttendanceRecordEntity> records,
  ) async {
    saved.addAll(records);
    recordsController.add(List.from(saved));
  }

  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceEntity record) async {}

  @override
  Future<void> saveLegacyAttendances(
    List<LegacyAttendanceEntity> records,
  ) async {}

  @override
  Stream<List<LegacyAttendanceEntity>> watchLegacyAttendance({
    bool includeDeleted = false,
  }) => Stream.value([]);
}

Widget _wrapPage({
  required List<Override> overrides,
  VoidCallback? onAddSubject,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(body: DashboardPage(onAddSubject: onAddSubject)),
    ),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final now = DateTime.now();
  final testSubject1 = SubjectEntity(
    id: 'sub_math',
    name: 'Mathematics',
    color: '#3B82F6',
    createdAt: now,
    updatedAt: now,
  );
  final testSubject2 = SubjectEntity(
    id: 'sub_phys',
    name: 'Physics',
    color: '#10B981',
    createdAt: now,
    updatedAt: now,
  );

  const testSettings = UserSettingsEntity(
    name: 'Suklal',
    programName: 'Computer Science & Engineering',
    courseName: 'CSE',
    startDate: '2026-08-01',
    minPercent: 75.0,
    classDays: [1, 2, 3, 4, 5],
  );

  void setTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('DashboardPage Widget Tests', () {
    testWidgets(
      'Renders Dashboard title exactly once, Program subtitle, OverviewCard, and AdvisorBanner',
      (tester) async {
        setTallScreen(tester);
        final fakeRepo = FakeAttendanceRepo();

        await tester.pumpWidget(
          _wrapPage(
            overrides: [
              attendanceRepositoryProvider.overrideWithValue(fakeRepo),
              subjectsStreamProvider.overrideWith((ref) => Stream.value([])),
              attendanceRecordsStreamProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
              legacyAttendanceStreamProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
              settingsStreamProvider.overrideWith(
                (ref) => Stream.value(testSettings),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // CRITICAL: Text 'Dashboard' must be found exactly once for app_router_test compatibility
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Computer Science & Engineering'), findsOneWidget);
        expect(find.byType(OverviewCard), findsOneWidget);
        expect(find.byType(AdvisorBanner), findsOneWidget);
        expect(find.text('Quick Attendance'), findsOneWidget);
      },
    );

    testWidgets('Renders EmptyDashboardView when no subjects exist', (
      tester,
    ) async {
      setTallScreen(tester);
      final fakeRepo = FakeAttendanceRepo();
      var addCalled = false;

      await tester.pumpWidget(
        _wrapPage(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(fakeRepo),
            subjectsStreamProvider.overrideWith((ref) => Stream.value([])),
            attendanceRecordsStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            legacyAttendanceStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            settingsStreamProvider.overrideWith(
              (ref) => Stream.value(testSettings),
            ),
          ],
          onAddSubject: () => addCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyDashboardView), findsOneWidget);
      expect(find.text('No subjects added yet'), findsOneWidget);

      await tester.tap(find.text('+ Add Subject'));
      await tester.pumpAndSettle();
      expect(addCalled, isTrue);
    });

    testWidgets('Renders QuickActionSubjectCard for each active subject', (
      tester,
    ) async {
      setTallScreen(tester);
      final fakeRepo = FakeAttendanceRepo();

      await tester.pumpWidget(
        _wrapPage(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(fakeRepo),
            subjectsStreamProvider.overrideWith(
              (ref) => Stream.value([testSubject1, testSubject2]),
            ),
            attendanceRecordsStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            legacyAttendanceStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            settingsStreamProvider.overrideWith(
              (ref) => Stream.value(testSettings),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyDashboardView), findsNothing);
      expect(find.byType(QuickActionSubjectCard), findsNWidgets(2));
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('2 subjects'), findsOneWidget);
    });

    testWidgets('Renders StreakBadge when streak > 0', (tester) async {
      setTallScreen(tester);
      final fakeRepo = FakeAttendanceRepo();
      // Attended today Wednesday 2026-11-18
      final record = AttendanceRecordEntity(
        id: 'rec_1',
        date:
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        subjectId: 'sub_math',
        sessionId: 'sess_1',
        status: AttendanceStatus.present,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        _wrapPage(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(fakeRepo),
            subjectsStreamProvider.overrideWith(
              (ref) => Stream.value([testSubject1]),
            ),
            attendanceRecordsStreamProvider.overrideWith(
              (ref) => Stream.value([record]),
            ),
            legacyAttendanceStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            settingsStreamProvider.overrideWith(
              (ref) => Stream.value(testSettings),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StreakBadge), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
    });

    testWidgets(
      'Tapping + Present logs attendance and displays SnackBar with Undo action',
      (tester) async {
        setTallScreen(tester);
        final fakeRepo = FakeAttendanceRepo();

        await tester.pumpWidget(
          _wrapPage(
            overrides: [
              attendanceRepositoryProvider.overrideWithValue(fakeRepo),
              subjectsStreamProvider.overrideWith(
                (ref) => Stream.value([testSubject1]),
              ),
              attendanceRecordsStreamProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
              legacyAttendanceStreamProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
              settingsStreamProvider.overrideWith(
                (ref) => Stream.value(testSettings),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Tap + Present on Mathematics card
        await tester.tap(find.text('+ Present'));
        await tester.pumpAndSettle();

        expect(fakeRepo.saved.length, 1);
        final recordedId = fakeRepo.saved.first.id;
        expect(fakeRepo.saved.first.subjectId, 'sub_math');
        expect(fakeRepo.saved.first.status, AttendanceStatus.present);

        // Verify SnackBar shown
        expect(find.text('Marked Mathematics as Present'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);

        // Tap Undo in SnackBar
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();

        expect(fakeRepo.deleted, contains(recordedId));
      },
    );

    testWidgets(
      'Tapping - Absent logs absent attendance and displays SnackBar with Undo action',
      (tester) async {
        setTallScreen(tester);
        final fakeRepo = FakeAttendanceRepo();

        await tester.pumpWidget(
          _wrapPage(
            overrides: [
              attendanceRepositoryProvider.overrideWithValue(fakeRepo),
              subjectsStreamProvider.overrideWith(
                (ref) => Stream.value([testSubject1]),
              ),
              attendanceRecordsStreamProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
              legacyAttendanceStreamProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
              settingsStreamProvider.overrideWith(
                (ref) => Stream.value(testSettings),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Tap - Absent on Mathematics card
        await tester.tap(find.text('- Absent'));
        await tester.pumpAndSettle();

        expect(fakeRepo.saved.length, 1);
        final recordedId = fakeRepo.saved.first.id;
        expect(fakeRepo.saved.first.subjectId, 'sub_math');
        expect(fakeRepo.saved.first.status, AttendanceStatus.absent);

        // Verify SnackBar shown
        expect(find.text('Marked Mathematics as Absent'), findsOneWidget);
        expect(find.text('Undo'), findsOneWidget);

        // Tap Undo in SnackBar
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();

        expect(fakeRepo.deleted, contains(recordedId));
      },
    );

    testWidgets(
      'Renders cleanly without overflow on compact mobile viewport Size(320, 568)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeRepo = FakeAttendanceRepo();
        final records = List.generate(
          10,
          (i) => AttendanceRecordEntity(
            id: 'rec_$i',
            date: '2026-11-${(i + 1).toString().padLeft(2, '0')}',
            subjectId: 'sub_math',
            sessionId: 'sess_$i',
            status: i < 9 ? AttendanceStatus.present : AttendanceStatus.absent,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await tester.pumpWidget(
          _wrapPage(
            overrides: [
              attendanceRepositoryProvider.overrideWithValue(fakeRepo),
              subjectsStreamProvider.overrideWith(
                (ref) => Stream.value([testSubject1, testSubject2]),
              ),
              attendanceRecordsStreamProvider.overrideWith(
                (ref) => Stream.value(records),
              ),
              legacyAttendanceStreamProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
              settingsStreamProvider.overrideWith(
                (ref) => Stream.value(testSettings),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Dashboard'), findsOneWidget);

        await tester.scrollUntilVisible(find.text('Quick Attendance'), 100);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Quick Attendance'), findsOneWidget);
        expect(find.text('2 subjects'), findsOneWidget);
        expect(find.byType(QuickActionSubjectCard), findsWidgets);
      },
    );

    testWidgets(
      'Renders cleanly without overflow on compact mobile viewport Size(360, 640)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeRepo = FakeAttendanceRepo();
        final records = List.generate(
          10,
          (i) => AttendanceRecordEntity(
            id: 'rec_$i',
            date: '2026-11-${(i + 1).toString().padLeft(2, '0')}',
            subjectId: 'sub_math',
            sessionId: 'sess_$i',
            status: i < 9 ? AttendanceStatus.present : AttendanceStatus.absent,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await tester.pumpWidget(
          _wrapPage(
            overrides: [
              attendanceRepositoryProvider.overrideWithValue(fakeRepo),
              subjectsStreamProvider.overrideWith(
                (ref) => Stream.value([testSubject1, testSubject2]),
              ),
              attendanceRecordsStreamProvider.overrideWith(
                (ref) => Stream.value(records),
              ),
              legacyAttendanceStreamProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
              settingsStreamProvider.overrideWith(
                (ref) => Stream.value(testSettings),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Dashboard'), findsOneWidget);

        await tester.scrollUntilVisible(find.text('Quick Attendance'), 100);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Quick Attendance'), findsOneWidget);
        expect(find.text('2 subjects'), findsOneWidget);
        expect(find.byType(QuickActionSubjectCard), findsWidgets);
      },
    );
  });
}
