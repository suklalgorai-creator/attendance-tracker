import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/utils/attendance_calculator.dart';
import 'package:flutter_app/core/utils/data_migration.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:flutter_app/features/notes/domain/entities/note_entity.dart';
import 'package:flutter_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_app/features/settings/domain/services/backup_service.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';
import 'package:flutter_app/features/subjects/domain/repositories/subject_repository.dart';
import 'package:flutter_app/features/timetable/domain/entities/timetable_session_entity.dart';
import 'package:flutter_app/features/timetable/domain/repositories/timetable_repository.dart';

// In-memory fake repositories for testing BackupService parity
class _FakeSettingsRepo implements SettingsRepository {
  UserSettingsEntity settings = const UserSettingsEntity(name: 'Test User');
  @override
  Future<UserSettingsEntity> getSettings() async => settings;
  @override
  Stream<UserSettingsEntity> watchSettings() => Stream.value(settings);
  @override
  Future<void> saveSettings(UserSettingsEntity newSettings) async {
    settings = newSettings;
  }
  @override
  Future<void> resetSettings() async {
    settings = const UserSettingsEntity();
  }
}

class _FakeSubjectRepo implements SubjectRepository {
  List<SubjectEntity> subjects = [];
  @override
  Future<List<SubjectEntity>> getSubjects({bool includeDeleted = false}) async =>
      includeDeleted ? subjects : subjects.where((s) => !s.isDeleted).toList();
  @override
  Stream<List<SubjectEntity>> watchSubjects({bool includeDeleted = false}) =>
      Stream.value(includeDeleted ? subjects : subjects.where((s) => !s.isDeleted).toList());
  @override
  Future<SubjectEntity?> getSubjectById(String id) async =>
      subjects.cast<SubjectEntity?>().firstWhere((s) => s?.id == id, orElse: () => null);
  @override
  Future<void> saveSubject(SubjectEntity subject) async {
    subjects.removeWhere((s) => s.id == subject.id);
    subjects.add(subject);
  }
  @override
  Future<void> saveSubjects(List<SubjectEntity> newSubjects) async {
    for (final s in newSubjects) {
      subjects.removeWhere((e) => e.id == s.id);
      subjects.add(s);
    }
  }
  @override
  Future<void> reorderSubjects(List<String> orderedIds) async {}
  @override
  Future<void> deleteSubject(String id) async {
    final idx = subjects.indexWhere((s) => s.id == id);
    if (idx != -1) {
      subjects[idx] = subjects[idx].copyWith(deletedAt: DateTime.now());
    }
  }
  @override
  Future<void> restoreSubject(String id) async {}
  @override
  Future<void> hardDeleteSubject(String id) async {
    subjects.removeWhere((s) => s.id == id);
  }
}

class _FakeTimetableRepo implements TimetableRepository {
  Map<int, List<TimetableSessionEntity>> timetable = {};
  @override
  Future<Map<int, List<TimetableSessionEntity>>> getTimetable({bool includeDeleted = false}) async => timetable;
  @override
  Stream<Map<int, List<TimetableSessionEntity>>> watchTimetable({bool includeDeleted = false}) => Stream.value(timetable);
  @override
  Future<void> addSession(int dayOfWeek, String subjectId, {String? label}) async {}
  @override
  Future<void> removeSession(int dayOfWeek, String sessionId) async {}
  @override
  Future<void> saveTimetable(Map<int, List<TimetableSessionEntity>> newTimetable) async {
    timetable = Map.from(newTimetable);
  }
  @override
  Future<void> clearTimetable() async {
    timetable.clear();
  }
}

class _FakeAttendanceRepo implements AttendanceRepository {
  List<AttendanceRecordEntity> records = [];
  List<LegacyAttendanceEntity> legacy = [];
  @override
  Future<List<AttendanceRecordEntity>> getAttendanceRecords({bool includeDeleted = false}) async =>
      includeDeleted ? records : records.where((r) => !r.isDeleted).toList();
  @override
  Stream<List<AttendanceRecordEntity>> watchAttendanceRecords({bool includeDeleted = false}) =>
      Stream.value(includeDeleted ? records : records.where((r) => !r.isDeleted).toList());
  @override
  Future<List<AttendanceRecordEntity>> getRecordsForDate(String date, {bool includeDeleted = false}) async =>
      records.where((r) => r.date == date).toList();
  @override
  Future<List<AttendanceRecordEntity>> getRecordsForSubject(String subjectId, {bool includeDeleted = false}) async =>
      records.where((r) => r.subjectId == subjectId).toList();
  @override
  Future<void> saveAttendanceRecord(AttendanceRecordEntity record) async {
    records.removeWhere((r) => r.id == record.id);
    records.add(record);
  }
  @override
  Future<void> saveAttendanceRecords(List<AttendanceRecordEntity> newRecords) async {
    for (final r in newRecords) {
      records.removeWhere((e) => e.id == r.id);
      records.add(r);
    }
  }
  @override
  Future<void> deleteAttendanceRecord(String id) async {
    final idx = records.indexWhere((r) => r.id == id);
    if (idx != -1) {
      records[idx] = records[idx].copyWith(deletedAt: DateTime.now());
    }
  }
  @override
  Future<void> restoreAttendanceRecord(String id) async {}
  @override
  Future<void> hardDeleteAttendanceRecord(String id) async {
    records.removeWhere((r) => r.id == id);
  }
  @override
  Future<List<LegacyAttendanceEntity>> getLegacyAttendance({bool includeDeleted = false}) async =>
      includeDeleted ? legacy : legacy.where((l) => !l.isDeleted).toList();
  @override
  Stream<List<LegacyAttendanceEntity>> watchLegacyAttendance({bool includeDeleted = false}) =>
      Stream.value(includeDeleted ? legacy : legacy.where((l) => !l.isDeleted).toList());
  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceEntity entity) async {
    legacy.removeWhere((l) => l.id == entity.id);
    legacy.add(entity);
  }
  @override
  Future<void> saveLegacyAttendances(List<LegacyAttendanceEntity> entities) async {
    for (final e in entities) {
      legacy.removeWhere((l) => l.id == e.id);
      legacy.add(e);
    }
  }
  @override
  Future<void> deleteLegacyAttendance(String id) async {
    final idx = legacy.indexWhere((l) => l.id == id);
    if (idx != -1) {
      legacy[idx] = legacy[idx].copyWith(deletedAt: DateTime.now());
    }
  }
  @override
  Future<void> restoreLegacyAttendance(String id) async {}
  @override
  Future<void> hardDeleteLegacyAttendance(String id) async {
    legacy.removeWhere((l) => l.id == id);
  }
  @override
  Future<void> clearAllAttendanceHistory() async {
    records.clear();
    legacy.clear();
  }
}

class _FakeNotesRepo implements NotesRepository {
  List<NoteEntity> notes = [];
  @override
  Future<List<NoteEntity>> getNotes() async => notes;
  @override
  Stream<List<NoteEntity>> watchNotes() => Stream.value(notes);
  @override
  Future<NoteEntity?> getNoteById(String id) async =>
      notes.cast<NoteEntity?>().firstWhere((n) => n?.id == id, orElse: () => null);
  @override
  Future<void> saveNote(NoteEntity note) async {
    notes.removeWhere((n) => n.id == note.id);
    notes.add(note);
  }
  @override
  Future<void> saveNotes(List<NoteEntity> newNotes) async {
    for (final n in newNotes) {
      notes.removeWhere((e) => e.id == n.id);
      notes.add(n);
    }
  }
  @override
  Future<void> deleteNote(String id) async {
    notes.removeWhere((n) => n.id == id);
  }
  @override
  Future<void> clearAllNotes() async {
    notes.clear();
  }
}

void main() {
  group('Phase 5: Master Mathematical Parity Suite (1:1 with React attendance.test.js)', () {
    // -------------------------------------------------------------------------
    // Test 1: 'attendance percentage handles zero conducted classes consistently'
    // -------------------------------------------------------------------------
    test('attendance percentage handles zero conducted classes consistently', () {
      expect(calculateAttendance(0, 0), isNull);
      expect(calculateAttendance(5, 10), 50.0);
      expect(calculateAttendance(0, 10), 0.0);
    });

    // -------------------------------------------------------------------------
    // Test 2: 'safe-to-skip uses precise threshold math'
    // -------------------------------------------------------------------------
    test('safe-to-skip uses precise threshold math', () {
      expect(calculateMaximumAbsences(10, 10, 75), 3);
      expect(calculateMaximumAbsences(75, 100, 75), 0);
      expect(calculateMaximumAbsences(76, 100, 75), 1);
      expect(calculateMaximumAbsences(746, 1000, 75), 0);
    });

    // -------------------------------------------------------------------------
    // Test 3: 'recovery recommendations use the minimum integer solution'
    // -------------------------------------------------------------------------
    test('recovery recommendations use the minimum integer solution', () {
      expect(calculateRequiredRecoveryClasses(60, 100, 75), 60);
      expect(calculateRequiredRecoveryClasses(70, 100, 75), 20);
      expect(calculateRequiredRecoveryClasses(74, 100, 75), 4);
      expect(calculateRequiredRecoveryClasses(75, 100, 75), 0);
    });

    // -------------------------------------------------------------------------
    // Test 4: 'unmarked, cancelled and holidays do not reduce official attendance'
    // -------------------------------------------------------------------------
    test('unmarked, cancelled and holidays do not reduce official attendance', () {
      final subjects = [
        {'id': 'math', 'name': 'Maths'}
      ];
      final records = [
        {
          'id': 'p',
          'date': '2026-10-01',
          'subjectId': 'math',
          'sessionId': 's1',
          'status': AttendanceStatusConstants.present,
        },
        {
          'id': 'a',
          'date': '2026-10-02',
          'subjectId': 'math',
          'sessionId': 's2',
          'status': AttendanceStatusConstants.absent,
        },
        {
          'id': 'u',
          'date': '2026-10-03',
          'subjectId': 'math',
          'sessionId': 's3',
          'status': AttendanceStatusConstants.unmarked,
        },
        {
          'id': 'c',
          'date': '2026-10-04',
          'subjectId': 'math',
          'sessionId': 's4',
          'status': AttendanceStatusConstants.cancelled,
        },
        {
          'id': 'h',
          'date': '2026-10-05',
          'subjectId': 'math',
          'sessionId': 's5',
          'status': AttendanceStatusConstants.absent,
        },
      ];
      final normalized = migrateUserData({
        'schemaVersion': 2,
        'subjects': subjects,
        'attendanceRecords': records,
      }).data;

      final result = calculateOverallAttendance(
        attendanceRecords: normalized.attendanceRecords,
        minPercent: 75,
        holidays: {'2026-10-05': 'Holiday'},
      );

      expect(
        {'present': result.present, 'absent': result.absent, 'conducted': result.conducted},
        {'present': 1, 'absent': 1, 'conducted': 2},
      );
      expect(result.attendance, 50.0);
    });

    // -------------------------------------------------------------------------
    // Test 5: 'invalid records are quarantined and valid records survive migration'
    // -------------------------------------------------------------------------
    test('invalid records are quarantined and valid records survive migration', () {
      final result = migrateUserData({
        'schemaVersion': 2,
        'subjects': [
          {'id': 'math', 'name': 'Maths'}
        ],
        'attendanceRecords': [
          {'id': 'valid', 'date': '2026-10-01', 'subjectId': 'math', 'sessionId': 's1', 'status': 'PRESENT'},
          {'id': 'bad-status', 'date': '2026-10-01', 'subjectId': 'math', 'sessionId': 's2', 'status': 'UNKNOWN'},
          {'id': 'bad-date', 'date': 'not-a-date', 'subjectId': 'math', 'sessionId': 's3', 'status': 'ABSENT'},
          {'id': 'bad-subject', 'date': '2026-10-01', 'subjectId': 'missing', 'sessionId': 's4', 'status': 'ABSENT'},
        ],
      });
      expect(result.data.attendanceRecords.length, 1);
      expect(result.quarantineCount, 3);
    });

    // -------------------------------------------------------------------------
    // Test 6: 'multiple classes on one date coexist independently'
    // -------------------------------------------------------------------------
    test('multiple classes on one date coexist independently', () {
      final result = migrateUserData({
        'schemaVersion': 2,
        'subjects': [
          {'id': 'math', 'name': 'Maths'},
          {'id': 'physics', 'name': 'Physics'}
        ],
        'attendanceRecords': [
          {'id': 'one', 'date': '2026-10-01', 'subjectId': 'math', 'sessionId': 'math-1', 'status': 'PRESENT'},
          {'id': 'two', 'date': '2026-10-01', 'subjectId': 'physics', 'sessionId': 'physics-1', 'status': 'ABSENT'},
        ],
      }).data;
      expect(result.attendanceRecords.length, 2);
      final subjectIds = result.attendanceRecords.map((record) => record.subjectId).toList()..sort();
      expect(subjectIds, ['math', 'physics']);
    });

    // -------------------------------------------------------------------------
    // Test 7: 'daily attendance works without a subject'
    // -------------------------------------------------------------------------
    test('daily attendance works without a subject', () {
      final data = migrateUserData({
        'schemaVersion': 2,
        'attendanceRecords': [
          {'id': 'daily-1', 'date': '2026-10-01', 'sessionId': 'daily-2026-10-01', 'status': 'PRESENT'},
          {'id': 'daily-2', 'date': '2026-10-02', 'sessionId': 'daily-2026-10-02', 'status': 'ABSENT'},
        ],
      }).data;
      expect(data.attendanceRecords[0].subjectId, '__daily__');
      final result = calculateOverallAttendance(
        attendanceRecords: data.attendanceRecords,
        minPercent: 75,
      );
      expect(
        {'present': result.present, 'absent': result.absent, 'conducted': result.conducted},
        {'present': 1, 'absent': 1, 'conducted': 2},
      );
    });

    // -------------------------------------------------------------------------
    // Test 8: 'sync keeps the newest entity and preserves deletions'
    // -------------------------------------------------------------------------
    test('sync keeps the newest entity and preserves deletions', () {
      final base = {
        'schemaVersion': 2,
        'subjects': [
          {'id': 'math', 'name': 'Maths'}
        ],
      };
      final local = {
        ...base,
        'updatedAt': '2026-10-07T10:05:00.000Z',
        'attendanceRecords': [
          {
            'id': 'r1',
            'date': '2026-10-01',
            'subjectId': 'math',
            'sessionId': 's1',
            'status': 'PRESENT',
            'updatedAt': '2026-10-05T10:05:00.000Z',
          }
        ],
      };
      final cloud = {
        ...base,
        'updatedAt': '2026-10-07T10:03:00.000Z',
        'attendanceRecords': [
          {
            'id': 'r1',
            'date': '2026-10-01',
            'subjectId': 'math',
            'sessionId': 's1',
            'status': 'ABSENT',
            'updatedAt': '2026-10-05T10:03:00.000Z',
          }
        ],
      };
      expect(mergeUserData(local, cloud).attendanceRecords[0].status, 'PRESENT');

      final localRecords = local['attendanceRecords'] as List;
      final firstRec = localRecords[0] as Map<String, dynamic>;
      final deleted = {
        ...local,
        'attendanceRecords': [
          {
            ...firstRec,
            'deletedAt': '2026-10-06T10:00:00.000Z',
            'updatedAt': '2026-10-06T10:00:00.000Z',
          }
        ],
      };
      expect(mergeUserData(deleted, cloud).attendanceRecords[0].deletedAt, '2026-10-06T10:00:00.000Z');
    });

    // -------------------------------------------------------------------------
    // Test 9: 'backup round-trip validates data before restore'
    // -------------------------------------------------------------------------
    test('backup round-trip validates data before restore', () {
      final backup = createBackup({
        'schemaVersion': 2,
        'subjects': [
          {'id': 'math', 'name': 'Maths'}
        ],
      });
      final parsed = parseBackup(jsonEncode(backup));
      expect(parsed.summary.subjects, 1);
      expect(
        () => parseBackup('{"format":"wrong","data":{}}'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not a College Attendance Tracker backup'),
          ),
        ),
      );
      expect(
        () => parseBackup(jsonEncode({...backup, 'schemaVersion': 999})),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('newer app version'),
          ),
        ),
      );

      // Parity check against BackupService implementation
      final backupService = BackupService(
        settingsRepository: _FakeSettingsRepo(),
        subjectRepository: _FakeSubjectRepo(),
        timetableRepository: _FakeTimetableRepo(),
        attendanceRepository: _FakeAttendanceRepo(),
        notesRepository: _FakeNotesRepo(),
      );
      final bsParsed = backupService.parseBackup(jsonEncode(backup));
      expect(bsParsed.isValid, isTrue);
      expect(bsParsed.summary?.subjectsCount, 1);

      final bsWrong = backupService.parseBackup('{"format":"wrong","data":{}}');
      expect(bsWrong.isValid, isFalse);
      expect(bsWrong.error, contains('not a College Attendance Tracker backup'));

      final bsNewer = backupService.parseBackup(jsonEncode({...backup, 'schemaVersion': 999}));
      expect(bsNewer.isValid, isFalse);
      expect(bsNewer.error, contains('newer app version'));
    });
  });

  group('Phase 5: Adversarial Boundary & Domain Entity Math Verification', () {
    test('calculateOverallAttendance combining session records and legacy aggregates', () {
      final now = DateTime.now();
      final records = [
        AttendanceRecordEntity(
          id: 'r1',
          date: '2026-10-01',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        ),
        AttendanceRecordEntity(
          id: 'r2',
          date: '2026-10-02',
          sessionId: 's2',
          status: AttendanceStatus.absent,
          createdAt: now,
          updatedAt: now,
        ),
        AttendanceRecordEntity(
          id: 'r3',
          date: '2026-10-03',
          sessionId: 's3',
          status: AttendanceStatus.cancelled,
          createdAt: now,
          updatedAt: now,
        ),
        AttendanceRecordEntity(
          id: 'r4',
          date: '2026-10-04',
          sessionId: 's4',
          status: AttendanceStatus.unmarked,
          createdAt: now,
          updatedAt: now,
        ),
        AttendanceRecordEntity(
          id: 'r5_del',
          date: '2026-10-05',
          sessionId: 's5',
          status: AttendanceStatus.absent,
          createdAt: now,
          updatedAt: now,
          deletedAt: now,
        ),
      ];

      final legacy = [
        LegacyAttendanceEntity(
          id: 'l1',
          date: '2026-09-01',
          held: 5,
          attended: 4,
          createdAt: now,
          updatedAt: now,
        ),
        LegacyAttendanceEntity(
          id: 'l2_del',
          date: '2026-09-02',
          held: 10,
          attended: 2,
          createdAt: now,
          updatedAt: now,
          deletedAt: now,
        ),
      ];

      // Sessions: present=1, absent=1, conducted=2, cancelled=1, unmarked=1
      // Legacy: held=5, attended=4 -> present=4, absent=1, conducted=5
      // Combined: present=5, absent=2, conducted=7 -> (5/7)*100 = 71.42857%
      final result = calculateOverallAttendance(
        attendanceRecords: records,
        legacyAttendance: legacy,
        minPercent: 75,
      );

      expect(result.present, 5);
      expect(result.absent, 2);
      expect(result.conducted, 7);
      expect(result.cancelled, 1);
      expect(result.unmarked, 1);
      expect(result.status, 'danger');
      expect(result.isDanger, isTrue);
      expect(result.isSafe, isFalse);
      expect(result.canMiss, 0);
      // Recovery for 5/7 @ 75: ((75*7) - (100*5)) / (100 - 75) = (525 - 500) / 25 = 25/25 = 1.
      expect(result.needToAttend, 1);
      expect(result.impossible, isFalse);
    });

    test('calculateSubjectAttendance filters strictly by subject and calculates metrics', () {
      final now = DateTime.now();
      final records = [
        AttendanceRecordEntity(
          id: 'math1',
          date: '2026-10-01',
          subjectId: 'math',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        ),
        AttendanceRecordEntity(
          id: 'math2',
          date: '2026-10-02',
          subjectId: 'math',
          sessionId: 's2',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        ),
        AttendanceRecordEntity(
          id: 'cs1',
          date: '2026-10-01',
          subjectId: 'cs',
          sessionId: 's3',
          status: AttendanceStatus.absent,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final mathResult = calculateSubjectAttendance(
        'math',
        attendanceRecords: records,
        minPercent: 75,
      );

      expect(mathResult.subjectId, 'math');
      expect(mathResult.present, 2);
      expect(mathResult.absent, 0);
      expect(mathResult.conducted, 2);
      expect(mathResult.attendance, 100.0);
      expect(mathResult.status, 'safe');
      expect(mathResult.isSafe, isTrue);
      // 2/2 @ 75%: floor(200/75 - 2 + 1e-10) = floor(2.6666 - 2) = 0
      expect(mathResult.canMiss, 0);
      expect(mathResult.needToAttend, 0);

      final csResult = calculateSubjectAttendance(
        'cs',
        attendanceRecords: records,
        minPercent: 75,
      );
      expect(csResult.subjectId, 'cs');
      expect(csResult.present, 0);
      expect(csResult.absent, 1);
      expect(csResult.conducted, 1);
      expect(csResult.attendance, 0.0);
      expect(csResult.status, 'danger');
      // 0/1 @ 75%: ceil((75 - 0)/25) = 3
      expect(csResult.needToAttend, 3);
    });

    test('isConductedAttendanceRecord recognizes present/absent and rejects cancelled/unmarked/deleted', () {
      final now = DateTime.now();
      expect(
        isConductedAttendanceRecord(AttendanceRecordEntity(
          id: '1',
          date: '2026-10-01',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        )),
        isTrue,
      );
      expect(
        isConductedAttendanceRecord(AttendanceRecordEntity(
          id: '2',
          date: '2026-10-01',
          sessionId: 's1',
          status: AttendanceStatus.absent,
          createdAt: now,
          updatedAt: now,
        )),
        isTrue,
      );
      expect(
        isConductedAttendanceRecord(AttendanceRecordEntity(
          id: '3',
          date: '2026-10-01',
          sessionId: 's1',
          status: AttendanceStatus.cancelled,
          createdAt: now,
          updatedAt: now,
        )),
        isFalse,
      );
      expect(
        isConductedAttendanceRecord(AttendanceRecordEntity(
          id: '4',
          date: '2026-10-01',
          sessionId: 's1',
          status: AttendanceStatus.unmarked,
          createdAt: now,
          updatedAt: now,
        )),
        isFalse,
      );
      expect(
        isConductedAttendanceRecord(AttendanceRecordEntity(
          id: '5',
          date: '2026-10-01',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
          deletedAt: now,
        )),
        isFalse,
      );
      expect(isConductedAttendanceRecord(null), isFalse);
      expect(isConductedAttendanceRecord({'status': 'PRESENT', 'deletedAt': null}), isTrue);
      expect(isConductedAttendanceRecord({'status': 'ABSENT', 'deletedAt': '2026-10-01'}), isFalse);
    });

    test('calculatePendingScheduledSessions counts unlogged and unmarked scheduled periods', () {
      final timetable = {
        // Monday (1)
        '1': [
          {'id': 'sess-1', 'subjectId': 'math', 'active': true},
          {'id': 'sess-2', 'subjectId': 'cs', 'active': true},
        ],
        // Tuesday (2)
        '2': [
          {'id': 'sess-3', 'subjectId': 'physics', 'active': true},
        ],
      };

      // 2026-10-05 was Monday, 2026-10-06 was Tuesday
      final records = [
        {'date': '2026-10-05', 'sessionId': 'sess-1', 'status': 'PRESENT'},
        {'date': '2026-10-05', 'sessionId': 'sess-2', 'status': 'UNMARKED'},
      ];

      final pending = calculatePendingScheduledSessions(
        attendanceRecords: records,
        timetable: timetable,
        classDays: [1, 2],
        startDate: '2026-10-05',
        endDate: '2026-10-06',
      );

      // On 2026-10-05 (Monday): sess-1 is marked PRESENT (not pending), sess-2 is UNMARKED (pending = 1)
      // On 2026-10-06 (Tuesday): sess-3 has no record (pending = 1)
      // Total pending = 2
      expect(pending, 2);
    });

    test('100% threshold impossible behavior', () {
      final result = calculateOverallAttendance(
        attendanceRecords: [
          {'date': '2026-10-01', 'sessionId': 's1', 'status': 'ABSENT'}
        ],
        minPercent: 100,
      );
      expect(result.status, 'danger');
      expect(result.impossible, isTrue);
      expect(result.needToAttend, -1);
    });
  });
}
