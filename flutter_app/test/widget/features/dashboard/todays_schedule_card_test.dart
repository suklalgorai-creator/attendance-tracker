import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/todays_schedule_card.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';
import 'package:flutter_app/features/timetable/domain/entities/timetable_session_entity.dart';

class FakeAttendanceRepo implements AttendanceRepository {
  final List<AttendanceRecordEntity> saved = [];

  @override
  Future<void> saveAttendanceRecords(
    List<AttendanceRecordEntity> records,
  ) async {
    saved.addAll(records);
  }

  @override
  Future<void> saveAttendanceRecord(AttendanceRecordEntity record) async {
    saved.add(record);
  }

  @override
  Future<List<AttendanceRecordEntity>> getAttendanceRecords({
    bool includeDeleted = false,
  }) async => saved;

  @override
  Stream<List<AttendanceRecordEntity>> watchAttendanceRecords({
    bool includeDeleted = false,
  }) => Stream.value(saved);

  @override
  Future<void> clearAllAttendanceHistory() async => saved.clear();

  @override
  Future<void> deleteAttendanceRecord(String id) async {}

  @override
  Future<void> deleteLegacyAttendance(String id) async {}

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

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // Monday, March 2, 2026 (weekday: 1, 1 % 7 = 1)
  final mondayDate = DateTime(2026, 3, 2, 9, 30);
  final mondayDateStr = '2026-03-02';

  final mockSubjects = [
    SubjectEntity(
      id: 'sub-algo',
      name: 'Algorithms',
      createdAt: mondayDate,
      updatedAt: mondayDate,
    ),
    SubjectEntity(
      id: 'sub-db',
      name: 'Database Systems',
      createdAt: mondayDate,
      updatedAt: mondayDate,
    ),
  ];

  final mondayTimetable = {
    1: [
      TimetableSessionEntity(
        id: 'sess-algo-1',
        subjectId: 'sub-algo',
        label: 'Algorithms',
        dayOfWeek: 1,
        createdAt: mondayDate,
        updatedAt: mondayDate,
      ),
      TimetableSessionEntity(
        id: 'sess-db-1',
        subjectId: 'sub-db',
        label: 'Database Systems',
        dayOfWeek: 1,
        createdAt: mondayDate,
        updatedAt: mondayDate,
      ),
    ],
  };

  Widget buildCard({
    required FakeAttendanceRepo attendanceRepo,
    Map<int, List<TimetableSessionEntity>>? timetable,
    List<AttendanceRecordEntity>? records,
    UserSettingsEntity? settings,
    DateTime? testNow,
    VoidCallback? onReviewIndividually,
  }) {
    return ProviderScope(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(attendanceRepo),
        attendanceRecordsStreamProvider.overrideWith(
          (ref) => Stream.value(records ?? const []),
        ),
        timetableStreamProvider.overrideWith(
          (ref) => Stream.value(timetable ?? mondayTimetable),
        ),
        subjectsStreamProvider.overrideWith(
          (ref) => Stream.value(mockSubjects),
        ),
        settingsStreamProvider.overrideWith(
          (ref) => Stream.value(
            settings ?? const UserSettingsEntity(classDays: [1, 2, 3, 4, 5]),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TodaysScheduleCard(
              now: testNow ?? mondayDate,
              onReviewIndividually: onReviewIndividually,
            ),
          ),
        ),
      ),
    );
  }

  group('TodaysScheduleCard Widget Tests', () {
    testWidgets('renders when today has scheduled unmarked sessions', (
      tester,
    ) async {
      final repo = FakeAttendanceRepo();

      await tester.pumpWidget(buildCard(attendanceRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text("Mark Today's Scheduled Sessions"), findsOneWidget);
      expect(find.text('Algorithms'), findsOneWidget);
      expect(find.text('Database Systems'), findsOneWidget);
      expect(find.text('Mark all present'), findsOneWidget);
      expect(find.text('Mark all absent'), findsOneWidget);
      expect(find.text('Review individually'), findsOneWidget);
    });

    testWidgets('collapses when today has no scheduled sessions', (
      tester,
    ) async {
      final repo = FakeAttendanceRepo();

      // Sunday: March 1, 2026 (weekday: 7, 7 % 7 = 0)
      final sundayDate = DateTime(2026, 3, 1, 10, 0);

      await tester.pumpWidget(
        buildCard(
          attendanceRepo: repo,
          testNow: sundayDate,
          timetable: mondayTimetable, // Only Monday has sessions
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Mark Today's Scheduled Sessions"), findsNothing);
    });

    testWidgets('collapses when today is not a class day in settings', (
      tester,
    ) async {
      final repo = FakeAttendanceRepo();

      final settingsWithoutMonday = const UserSettingsEntity(
        classDays: [2, 3, 4, 5], // Monday (1) not configured as class day
      );

      await tester.pumpWidget(
        buildCard(attendanceRepo: repo, settings: settingsWithoutMonday),
      );
      await tester.pumpAndSettle();

      expect(find.text("Mark Today's Scheduled Sessions"), findsNothing);
    });

    testWidgets(
      'collapses when all scheduled sessions for today are already marked',
      (tester) async {
        final repo = FakeAttendanceRepo();

        final markedRecords = [
          AttendanceRecordEntity(
            id: 'att_1',
            date: mondayDateStr,
            subjectId: 'sub-algo',
            sessionId: 'sess-algo-1',
            status: AttendanceStatus.present,
            createdAt: mondayDate,
            updatedAt: mondayDate,
          ),
          AttendanceRecordEntity(
            id: 'att_2',
            date: mondayDateStr,
            subjectId: 'sub-db',
            sessionId: 'sess-db-1',
            status: AttendanceStatus.absent,
            createdAt: mondayDate,
            updatedAt: mondayDate,
          ),
        ];

        await tester.pumpWidget(
          buildCard(attendanceRepo: repo, records: markedRecords),
        );
        await tester.pumpAndSettle();

        expect(find.text("Mark Today's Scheduled Sessions"), findsNothing);
      },
    );

    testWidgets(
      'tapping "Mark all present" saves all sessions with status present',
      (tester) async {
        final repo = FakeAttendanceRepo();

        await tester.pumpWidget(buildCard(attendanceRepo: repo));
        await tester.pumpAndSettle();

        final markPresentBtn = find.text('Mark all present');
        await tester.tap(markPresentBtn);
        await tester.pumpAndSettle();

        expect(repo.saved.length, 2);
        expect(
          repo.saved.every((r) => r.status == AttendanceStatus.present),
          isTrue,
        );
        expect(repo.saved.every((r) => r.date == mondayDateStr), isTrue);
      },
    );

    testWidgets(
      'tapping "Mark all absent" saves all sessions with status absent',
      (tester) async {
        final repo = FakeAttendanceRepo();

        await tester.pumpWidget(buildCard(attendanceRepo: repo));
        await tester.pumpAndSettle();

        final markAbsentBtn = find.text('Mark all absent');
        await tester.tap(markAbsentBtn);
        await tester.pumpAndSettle();

        expect(repo.saved.length, 2);
        expect(
          repo.saved.every((r) => r.status == AttendanceStatus.absent),
          isTrue,
        );
        expect(repo.saved.every((r) => r.date == mondayDateStr), isTrue);
      },
    );

    testWidgets(
      'tapping "Review individually" calls onReviewIndividually callback',
      (tester) async {
        final repo = FakeAttendanceRepo();
        bool reviewed = false;

        await tester.pumpWidget(
          buildCard(
            attendanceRepo: repo,
            onReviewIndividually: () => reviewed = true,
          ),
        );
        await tester.pumpAndSettle();

        final reviewBtn = find.text('Review individually');
        await tester.tap(reviewBtn);
        await tester.pumpAndSettle();

        expect(reviewed, isTrue);
      },
    );

    testWidgets('320px narrow screen width renders without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeAttendanceRepo();

      await tester.pumpWidget(buildCard(attendanceRepo: repo));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("Mark Today's Scheduled Sessions"), findsOneWidget);
    });
  });
}
