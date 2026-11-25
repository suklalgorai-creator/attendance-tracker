import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';
import 'package:flutter_app/features/subjects/domain/repositories/subject_repository.dart';
import 'package:flutter_app/features/subjects/presentation/pages/subject_analytics_screen.dart';

class ScreenTestSubjectRepository implements SubjectRepository {
  final List<SubjectEntity> subjects = [];
  final _controller = StreamController<List<SubjectEntity>>.broadcast();

  void _notify() => _controller.add(List.unmodifiable(subjects));

  @override
  Future<List<SubjectEntity>> getSubjects({bool includeDeleted = false}) async {
    if (includeDeleted) return List.from(subjects);
    return subjects.where((s) => !s.isDeleted).toList();
  }

  @override
  Stream<List<SubjectEntity>> watchSubjects({
    bool includeDeleted = false,
  }) async* {
    yield List.from(subjects);
    yield* _controller.stream;
  }

  @override
  Future<SubjectEntity?> getSubjectById(String id) async {
    final match = subjects.where((s) => s.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<void> saveSubject(SubjectEntity subject) async {
    final index = subjects.indexWhere((s) => s.id == subject.id);
    if (index >= 0) {
      subjects[index] = subject;
    } else {
      subjects.add(subject);
    }
    _notify();
  }

  @override
  Future<void> saveSubjects(List<SubjectEntity> list) async {
    subjects.clear();
    subjects.addAll(list);
    _notify();
  }

  @override
  Future<void> deleteSubject(String id) async {
    final index = subjects.indexWhere((s) => s.id == id);
    if (index >= 0) {
      subjects[index] = subjects[index].copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> restoreSubject(String id) async {
    final index = subjects.indexWhere((s) => s.id == id);
    if (index >= 0) {
      subjects[index] = subjects[index].copyWith(
        clearDeletedAt: true,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> hardDeleteSubject(String id) async {
    subjects.removeWhere((s) => s.id == id);
    _notify();
  }

  @override
  Future<void> reorderSubjects(List<String> orderedIds) async {
    _notify();
  }
}

class ScreenTestAttendanceRepository implements AttendanceRepository {
  final List<AttendanceRecordEntity> records = [];
  final _controller =
      StreamController<List<AttendanceRecordEntity>>.broadcast();

  void _notify() => _controller.add(List.unmodifiable(records));

  @override
  Future<List<AttendanceRecordEntity>> getAttendanceRecords({
    bool includeDeleted = false,
  }) async {
    if (includeDeleted) return List.from(records);
    return records.where((r) => !r.isDeleted).toList();
  }

  @override
  Stream<List<AttendanceRecordEntity>> watchAttendanceRecords({
    bool includeDeleted = false,
  }) async* {
    if (includeDeleted) {
      yield List.from(records);
    } else {
      yield records.where((r) => !r.isDeleted).toList();
    }
    yield* _controller.stream.map((list) {
      if (includeDeleted) return list;
      return list.where((r) => !r.isDeleted).toList();
    });
  }

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForDate(
    String date, {
    bool includeDeleted = false,
  }) async {
    return records
        .where((r) => (includeDeleted || !r.isDeleted) && r.date == date)
        .toList();
  }

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForSubject(
    String subjectId, {
    bool includeDeleted = false,
  }) async {
    return records
        .where(
          (r) => (includeDeleted || !r.isDeleted) && r.subjectId == subjectId,
        )
        .toList();
  }

  @override
  Future<void> restoreAttendanceRecord(String id) async {
    final index = records.indexWhere((r) => r.id == id);
    if (index >= 0) {
      records[index] = records[index].copyWith(
        clearDeletedAt: true,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<List<LegacyAttendanceEntity>> getLegacyAttendance({
    bool includeDeleted = false,
  }) async => [];

  @override
  Stream<List<LegacyAttendanceEntity>> watchLegacyAttendance({
    bool includeDeleted = false,
  }) => const Stream.empty();

  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceEntity record) async {}

  @override
  Future<void> saveLegacyAttendances(
    List<LegacyAttendanceEntity> records,
  ) async {}

  @override
  Future<void> deleteLegacyAttendance(String id) async {}

  @override
  Future<void> restoreLegacyAttendance(String id) async {}

  @override
  Future<void> hardDeleteLegacyAttendance(String id) async {}

  @override
  Future<void> clearAllAttendanceHistory() async {
    records.clear();
    _notify();
  }

  @override
  Future<void> saveAttendanceRecord(AttendanceRecordEntity record) async {
    final index = records.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    _notify();
  }

  @override
  Future<void> saveAttendanceRecords(
    List<AttendanceRecordEntity> newRecords,
  ) async {
    for (final r in newRecords) {
      final index = records.indexWhere((item) => item.id == r.id);
      if (index >= 0) {
        records[index] = r;
      } else {
        records.add(r);
      }
    }
    _notify();
  }

  @override
  Future<void> deleteAttendanceRecord(String id) async {
    final index = records.indexWhere((r) => r.id == id);
    if (index >= 0) {
      records[index] = records[index].copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> hardDeleteAttendanceRecord(String id) async {
    records.removeWhere((r) => r.id == id);
    _notify();
  }

  Future<AttendanceRecordEntity?> getAttendanceRecordById(String id) async {
    final match = records.where((r) => r.id == id);
    return match.isNotEmpty ? match.first : null;
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  void setTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  const testSettings = UserSettingsEntity(
    name: 'Suklal',
    programName: 'Computer Science & Engineering',
    courseName: 'CSE',
    startDate: '2026-08-01',
    minPercent: 75.0,
    classDays: [1, 2, 3, 4, 5],
  );

  Widget createTestWidget({
    required ScreenTestSubjectRepository subjectRepo,
    required ScreenTestAttendanceRepository attendanceRepo,
    required String subjectId,
  }) {
    return ProviderScope(
      overrides: [
        subjectRepositoryProvider.overrideWithValue(subjectRepo),
        attendanceRepositoryProvider.overrideWithValue(attendanceRepo),
        subjectsStreamProvider.overrideWith(
          (ref) => subjectRepo.watchSubjects(),
        ),
        attendanceRecordsStreamProvider.overrideWith(
          (ref) => attendanceRepo.watchAttendanceRecords(),
        ),
        settingsStreamProvider.overrideWith(
          (ref) => Stream.value(testSettings),
        ),
      ],
      child: MaterialApp(home: SubjectAnalyticsScreen(subjectId: subjectId)),
    );
  }

  group('SubjectAnalyticsScreen Widget Tests', () {
    late ScreenTestSubjectRepository subjectRepo;
    late ScreenTestAttendanceRepository attendanceRepo;
    final now = DateTime(2026, 3, 1, 10, 0);

    final testSubject = SubjectEntity(
      id: 'sub_net',
      name: 'Computer Networks',
      code: 'CS301',
      color: '#3B82F6',
      icon: 'computer',
      targetPercentage: 80.0,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      subjectRepo = ScreenTestSubjectRepository();
      attendanceRepo = ScreenTestAttendanceRepository();
    });

    testWidgets(
      'Renders subject header with name, code, target badge and edit button',
      (tester) async {
        setTallScreen(tester);
        await subjectRepo.saveSubject(testSubject);

        await tester.pumpWidget(
          createTestWidget(
            subjectRepo: subjectRepo,
            attendanceRepo: attendanceRepo,
            subjectId: 'sub_net',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Computer Networks'), findsOneWidget);
        expect(find.text('CS301'), findsOneWidget);
        expect(find.text('TARGET 80%'), findsOneWidget);
        expect(find.byKey(const Key('subject_back_button')), findsOneWidget);
        expect(find.byKey(const Key('edit_subject_button')), findsOneWidget);
      },
    );

    testWidgets('Renders AttendanceRing and stats breakdown with records', (
      tester,
    ) async {
      setTallScreen(tester);
      await subjectRepo.saveSubject(testSubject);

      final records = [
        AttendanceRecordEntity(
          id: 'r1',
          date: '2026-03-01',
          subjectId: 'sub_net',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        ),
        AttendanceRecordEntity(
          id: 'r2',
          date: '2026-03-02',
          subjectId: 'sub_net',
          sessionId: 's2',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        ),
        AttendanceRecordEntity(
          id: 'r3',
          date: '2026-03-03',
          subjectId: 'sub_net',
          sessionId: 's3',
          status: AttendanceStatus.absent,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      await attendanceRepo.saveAttendanceRecords(records);

      await tester.pumpWidget(
        createTestWidget(
          subjectRepo: subjectRepo,
          attendanceRepo: attendanceRepo,
          subjectId: 'sub_net',
        ),
      );
      await tester.pumpAndSettle();

      // Attendance: 2 / 3 = 66.7%
      expect(find.text('66.7%'), findsOneWidget);
      expect(find.text('2 attended of 3 held'), findsOneWidget);
      expect(find.text('CONDUCTED CLASSES'), findsOneWidget);
      expect(find.text('PRESENT SESSIONS'), findsOneWidget);
      expect(find.text('ABSENT SESSIONS'), findsOneWidget);
      expect(find.text('TARGET THRESHOLD'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // Conducted count
      expect(find.text('2'), findsWidgets); // Present count
      expect(find.text('1'), findsWidgets); // Absent count
    });

    testWidgets('Renders session history rows with date and status badge', (
      tester,
    ) async {
      setTallScreen(tester);
      await subjectRepo.saveSubject(testSubject);

      final records = [
        AttendanceRecordEntity(
          id: 'r1',
          date: '2026-03-01',
          subjectId: 'sub_net',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        ),
        AttendanceRecordEntity(
          id: 'r2',
          date: '2026-03-02',
          subjectId: 'sub_net',
          sessionId: 's2',
          status: AttendanceStatus.absent,
          createdAt: now,
          updatedAt: now,
        ),
      ];
      await attendanceRepo.saveAttendanceRecords(records);

      await tester.pumpWidget(
        createTestWidget(
          subjectRepo: subjectRepo,
          attendanceRepo: attendanceRepo,
          subjectId: 'sub_net',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session History'), findsOneWidget);
      expect(find.text('2026-03-01'), findsOneWidget);
      expect(find.text('2026-03-02'), findsOneWidget);
      expect(find.text('PRESENT'), findsOneWidget);
      expect(find.text('ABSENT'), findsOneWidget);
    });

    testWidgets('Renders empty state placeholder when no records exist', (
      tester,
    ) async {
      setTallScreen(tester);
      await subjectRepo.saveSubject(testSubject);

      await tester.pumpWidget(
        createTestWidget(
          subjectRepo: subjectRepo,
          attendanceRepo: attendanceRepo,
          subjectId: 'sub_net',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No classes recorded yet for this subject'),
        findsOneWidget,
      );
      expect(
        find.text('Use the buttons above to log your first class.'),
        findsOneWidget,
      );
    });

    testWidgets('Renders Subject Not Found when subjectId does not exist', (
      tester,
    ) async {
      setTallScreen(tester);

      await tester.pumpWidget(
        createTestWidget(
          subjectRepo: subjectRepo,
          attendanceRepo: attendanceRepo,
          subjectId: 'non_existent_id',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subject Not Found'), findsOneWidget);
      expect(find.byKey(const Key('not_found_back_button')), findsOneWidget);
    });

    testWidgets('Tapping + Present logs present record for this subject', (
      tester,
    ) async {
      setTallScreen(tester);
      await subjectRepo.saveSubject(testSubject);

      await tester.pumpWidget(
        createTestWidget(
          subjectRepo: subjectRepo,
          attendanceRepo: attendanceRepo,
          subjectId: 'sub_net',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('analytics_present_button')));
      await tester.pumpAndSettle();

      final records = await attendanceRepo.getRecordsForSubject('sub_net');
      expect(records.length, 1);
      expect(records.first.status, AttendanceStatus.present);
      expect(
        find.textContaining('Marked Computer Networks as Present'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping - Absent logs absent record for this subject', (
      tester,
    ) async {
      setTallScreen(tester);
      await subjectRepo.saveSubject(testSubject);

      await tester.pumpWidget(
        createTestWidget(
          subjectRepo: subjectRepo,
          attendanceRepo: attendanceRepo,
          subjectId: 'sub_net',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('analytics_absent_button')));
      await tester.pumpAndSettle();

      final records = await attendanceRepo.getRecordsForSubject('sub_net');
      expect(records.length, 1);
      expect(records.first.status, AttendanceStatus.absent);
      expect(
        find.textContaining('Marked Computer Networks as Absent'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Edit button opens SubjectDialog in Edit Mode', (
      tester,
    ) async {
      setTallScreen(tester);
      await subjectRepo.saveSubject(testSubject);

      await tester.pumpWidget(
        createTestWidget(
          subjectRepo: subjectRepo,
          attendanceRepo: attendanceRepo,
          subjectId: 'sub_net',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_subject_button')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Subject'), findsOneWidget);
      expect(find.byKey(const Key('delete_subject_button')), findsOneWidget);
    });

    testWidgets(
      'Responsive rendering: does not overflow on compact viewport Size(320, 568)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await subjectRepo.saveSubject(testSubject);

        await tester.pumpWidget(
          createTestWidget(
            subjectRepo: subjectRepo,
            attendanceRepo: attendanceRepo,
            subjectId: 'sub_net',
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Computer Networks'), findsOneWidget);
      },
    );
  });
}
