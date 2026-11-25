import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:flutter_app/features/notes/domain/entities/note_entity.dart';
import 'package:flutter_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:flutter_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_app/features/settings/domain/services/backup_service.dart';
import 'package:flutter_app/features/settings/presentation/providers/settings_controller.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';
import 'package:flutter_app/features/subjects/domain/repositories/subject_repository.dart';
import 'package:flutter_app/features/timetable/domain/entities/timetable_session_entity.dart';
import 'package:flutter_app/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

// In-memory isolated repos for full end-to-end integration test
class E2ESettingsRepo implements SettingsRepository {
  UserSettingsEntity _settings = const UserSettingsEntity(
    name: 'Rahul Sharma',
    programName: 'B.Tech Computer Science',
    courseName: 'Semester 5',
    minPercent: 75.0,
    classDays: [1, 2, 3, 4, 5],
    reminderTime: '18:00',
    pushNotificationsEnabled: true,
  );

  @override
  Future<UserSettingsEntity> getSettings() async => _settings;
  @override
  Stream<UserSettingsEntity> watchSettings() => Stream.value(_settings);
  @override
  Future<void> saveSettings(UserSettingsEntity s) async => _settings = s;
  @override
  Future<void> resetSettings() async => _settings = const UserSettingsEntity();
}

class E2ESubjectRepo implements SubjectRepository {
  final List<SubjectEntity> _subjects = [];

  @override
  Future<List<SubjectEntity>> getSubjects({
    bool includeDeleted = false,
  }) async => includeDeleted
      ? _subjects
      : _subjects.where((s) => !s.isDeleted).toList();
  @override
  Stream<List<SubjectEntity>> watchSubjects({bool includeDeleted = false}) =>
      Stream.value(
        includeDeleted
            ? _subjects
            : _subjects.where((s) => !s.isDeleted).toList(),
      );
  @override
  Future<SubjectEntity?> getSubjectById(String id) async => _subjects
      .cast<SubjectEntity?>()
      .firstWhere((s) => s?.id == id, orElse: () => null);
  @override
  Future<void> saveSubject(SubjectEntity s) async {
    _subjects.removeWhere((item) => item.id == s.id);
    _subjects.add(s);
  }

  @override
  Future<void> saveSubjects(List<SubjectEntity> list) async {
    for (final s in list) {
      await saveSubject(s);
    }
  }

  @override
  Future<void> reorderSubjects(List<String> orderedIds) async {}
  @override
  Future<void> deleteSubject(String id) async {
    final idx = _subjects.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _subjects[idx] = _subjects[idx].copyWith(deletedAt: DateTime.now());
    }
  }

  @override
  Future<void> restoreSubject(String id) async {}
  @override
  Future<void> hardDeleteSubject(String id) async =>
      _subjects.removeWhere((s) => s.id == id);
}

class E2EAttendanceRepo implements AttendanceRepository {
  final List<AttendanceRecordEntity> _records = [];
  final List<LegacyAttendanceEntity> _legacy = [];

  @override
  Future<List<AttendanceRecordEntity>> getAttendanceRecords({
    bool includeDeleted = false,
  }) async =>
      includeDeleted ? _records : _records.where((r) => !r.isDeleted).toList();
  @override
  Stream<List<AttendanceRecordEntity>> watchAttendanceRecords({
    bool includeDeleted = false,
  }) => Stream.value(
    includeDeleted ? _records : _records.where((r) => !r.isDeleted).toList(),
  );
  @override
  Future<List<AttendanceRecordEntity>> getRecordsForDate(
    String date, {
    bool includeDeleted = false,
  }) async => _records.where((r) => r.date == date).toList();
  @override
  Future<List<AttendanceRecordEntity>> getRecordsForSubject(
    String subjectId, {
    bool includeDeleted = false,
  }) async => _records.where((r) => r.subjectId == subjectId).toList();
  @override
  Future<void> saveAttendanceRecord(AttendanceRecordEntity r) async {
    _records.removeWhere((item) => item.id == r.id);
    _records.add(r);
  }

  @override
  Future<void> saveAttendanceRecords(List<AttendanceRecordEntity> list) async {
    for (final r in list) {
      await saveAttendanceRecord(r);
    }
  }

  @override
  Future<void> deleteAttendanceRecord(String id) async {
    final idx = _records.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _records[idx] = _records[idx].copyWith(deletedAt: DateTime.now());
    }
  }

  @override
  Future<void> restoreAttendanceRecord(String id) async {}
  @override
  Future<void> hardDeleteAttendanceRecord(String id) async =>
      _records.removeWhere((r) => r.id == id);
  @override
  Future<List<LegacyAttendanceEntity>> getLegacyAttendance({
    bool includeDeleted = false,
  }) async => _legacy;
  @override
  Stream<List<LegacyAttendanceEntity>> watchLegacyAttendance({
    bool includeDeleted = false,
  }) => Stream.value(_legacy);
  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceEntity r) async =>
      _legacy.add(r);
  @override
  Future<void> saveLegacyAttendances(List<LegacyAttendanceEntity> list) async =>
      _legacy.addAll(list);
  @override
  Future<void> deleteLegacyAttendance(String id) async {}
  @override
  Future<void> restoreLegacyAttendance(String id) async {}
  @override
  Future<void> hardDeleteLegacyAttendance(String id) async {}
  @override
  Future<void> clearAllAttendanceHistory() async {
    _records.clear();
    _legacy.clear();
  }
}

class E2ETimetableRepo implements TimetableRepository {
  Map<int, List<TimetableSessionEntity>> _timetable = {};

  @override
  Future<Map<int, List<TimetableSessionEntity>>> getTimetable({
    bool includeDeleted = false,
  }) async => _timetable;
  @override
  Stream<Map<int, List<TimetableSessionEntity>>> watchTimetable({
    bool includeDeleted = false,
  }) => Stream.value(_timetable);
  @override
  Future<void> addSession(
    int dayOfWeek,
    String subjectId, {
    String? label,
  }) async {}
  @override
  Future<void> removeSession(int dayOfWeek, String sessionId) async {}
  @override
  Future<void> clearTimetable() async => _timetable.clear();
  @override
  Future<void> saveTimetable(Map<int, List<TimetableSessionEntity>> t) async =>
      _timetable = Map.from(t);
}

class FakeNotesRepo implements NotesRepository {
  @override
  Future<List<NoteEntity>> getNotes() async => [];
  @override
  Stream<List<NoteEntity>> watchNotes() => Stream.value([]);
  @override
  Future<NoteEntity?> getNoteById(String id) async => null;
  @override
  Future<void> saveNote(NoteEntity note) async {}
  @override
  Future<void> saveNotes(List<NoteEntity> notes) async {}
  @override
  Future<void> deleteNote(String id) async {}
  @override
  Future<void> clearAllNotes() async {}
}

class E2EBox implements Box {
  final Map<dynamic, dynamic> _store = {};
  @override
  dynamic get(key, {defaultValue}) =>
      _store.containsKey(key) ? _store[key] : defaultValue;
  @override
  Future<void> put(key, value) async => _store[key] = value;
  @override
  Future<void> delete(key) async => _store.remove(key);
  @override
  Future<int> clear() async {
    final c = _store.length;
    _store.clear();
    return c;
  }

  @override
  bool containsKey(key) => _store.containsKey(key);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 7: End-to-End User Journey Tests', () {
    late E2ESettingsRepo settingsRepo;
    late E2ESubjectRepo subjectRepo;
    late E2EAttendanceRepo attendanceRepo;
    late E2ETimetableRepo timetableRepo;
    late E2EBox box;
    late BackupService backupService;

    setUp(() {
      settingsRepo = E2ESettingsRepo();
      subjectRepo = E2ESubjectRepo();
      attendanceRepo = E2EAttendanceRepo();
      timetableRepo = E2ETimetableRepo();
      box = E2EBox();

      backupService = BackupService(
        settingsRepository: settingsRepo,
        subjectRepository: subjectRepo,
        timetableRepository: timetableRepo,
        attendanceRepository: attendanceRepo,
        notesRepository: FakeNotesRepo(),
        settingsBoxOverride: box,
      );
    });

    testWidgets(
      'Full User Journey: Subjects -> Attendance -> Dashboard -> Backup Cycle',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // 1. Create a subject (Algorithms, 4 credits, green)
        final subAlgorithms = SubjectEntity(
          id: 'sub_algo',
          name: 'Design & Analysis of Algorithms',
          code: 'CS501',
          color: '#10B981',
          createdAt: DateTime.parse('2026-11-20T09:00:00Z'),
          updatedAt: DateTime.parse('2026-11-20T09:00:00Z'),
        );
        await subjectRepo.saveSubject(subAlgorithms);

        // 2. Log 8 attended classes out of 10 conducted (80.0% -> Safe against 75% threshold)
        for (int i = 1; i <= 10; i++) {
          final dayStr = i < 10 ? '0$i' : '$i';
          await attendanceRepo.saveAttendanceRecord(
            AttendanceRecordEntity(
              id: 'rec_$i',
              date: '2026-11-$dayStr',
              sessionId: 'session_$i',
              subjectId: 'sub_algo',
              status: i <= 8
                  ? AttendanceStatus.present
                  : AttendanceStatus.absent,
              createdAt: DateTime.parse('2026-11-${dayStr}T10:00:00Z'),
              updatedAt: DateTime.parse('2026-11-${dayStr}T10:00:00Z'),
            ),
          );
        }

        // 3. Render Dashboard with Riverpod overrides
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(settingsRepo),
              subjectRepositoryProvider.overrideWithValue(subjectRepo),
              attendanceRepositoryProvider.overrideWithValue(attendanceRepo),
              timetableRepositoryProvider.overrideWithValue(timetableRepo),
              backupServiceProvider.overrideWithValue(backupService),
            ],
            child: const MaterialApp(home: Scaffold(body: DashboardPage())),
          ),
        );

        await tester.pumpAndSettle();

        // 4. Verify Dashboard displays DailyFlow, Attendance metrics & Subject Cards
        expect(find.text('DailyFlow'), findsOneWidget);
        expect(find.text('CONDUCTED'), findsWidgets);
        expect(find.text('PRESENT'), findsWidgets);
        expect(
          find.text('80.0%'),
          findsWidgets,
        ); // Overall and subject percentage
        expect(find.text('Design & Analysis of Algorithms'), findsOneWidget);

        // 5. Verify Backup export serialization preserves complete user journey data
        final backupEnvelope = await backupService.createBackup();
        expect(backupEnvelope['format'], 'college-attendance-tracker-backup');
        expect(backupEnvelope['schemaVersion'], 2);

        final exportedData = backupEnvelope['data'] as Map<String, dynamic>;
        expect(exportedData['name'], 'Rahul Sharma');
        expect(exportedData['programName'], 'B.Tech Computer Science');
        expect((exportedData['subjects'] as List).length, 1);
        expect((exportedData['attendanceRecords'] as List).length, 10);

        // 6. Verify Backup restore round-trip
        final restoreResult = await backupService.restoreBackup(exportedData);
        expect(restoreResult.ok, isTrue);

        final restoredSettings = await settingsRepo.getSettings();
        expect(restoredSettings.name, 'Rahul Sharma');
        expect(restoredSettings.minPercent, 75.0);
      },
    );
  });
}
