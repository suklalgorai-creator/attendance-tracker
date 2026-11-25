import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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
import 'package:hive_flutter/hive_flutter.dart';

// In-memory fake repositories for unit testing
class FakeSettingsRepo implements SettingsRepository {
  UserSettingsEntity settings = const UserSettingsEntity(name: 'Initial User');

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

class FakeSubjectRepo implements SubjectRepository {
  List<SubjectEntity> subjects = [];

  @override
  Future<List<SubjectEntity>> getSubjects({bool includeDeleted = false}) async {
    return includeDeleted
        ? subjects
        : subjects.where((s) => !s.isDeleted).toList();
  }

  @override
  Stream<List<SubjectEntity>> watchSubjects({bool includeDeleted = false}) =>
      Stream.value(
        includeDeleted
            ? subjects
            : subjects.where((s) => !s.isDeleted).toList(),
      );

  @override
  Future<SubjectEntity?> getSubjectById(String id) async {
    return subjects.cast<SubjectEntity?>().firstWhere(
      (s) => s?.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<void> saveSubject(SubjectEntity subject) async {
    subjects.removeWhere((s) => s.id == subject.id);
    subjects.add(subject);
  }

  @override
  Future<void> saveSubjects(List<SubjectEntity> newSubjects) async {
    for (final s in newSubjects) {
      subjects.removeWhere((existing) => existing.id == s.id);
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

class FakeTimetableRepo implements TimetableRepository {
  Map<int, List<TimetableSessionEntity>> timetable = {};

  @override
  Future<Map<int, List<TimetableSessionEntity>>> getTimetable({
    bool includeDeleted = false,
  }) async => timetable;

  @override
  Stream<Map<int, List<TimetableSessionEntity>>> watchTimetable({
    bool includeDeleted = false,
  }) => Stream.value(timetable);

  @override
  Future<void> addSession(
    int dayOfWeek,
    String subjectId, {
    String? label,
  }) async {}

  @override
  Future<void> removeSession(int dayOfWeek, String sessionId) async {}

  @override
  Future<void> clearTimetable() async {
    timetable.clear();
  }

  @override
  Future<void> saveTimetable(
    Map<int, List<TimetableSessionEntity>> newTimetable,
  ) async {
    timetable = Map.from(newTimetable);
  }
}

class FakeAttendanceRepo implements AttendanceRepository {
  List<AttendanceRecordEntity> records = [];
  List<LegacyAttendanceEntity> legacy = [];

  @override
  Future<List<AttendanceRecordEntity>> getAttendanceRecords({
    bool includeDeleted = false,
  }) async {
    return includeDeleted
        ? records
        : records.where((r) => !r.isDeleted).toList();
  }

  @override
  Stream<List<AttendanceRecordEntity>> watchAttendanceRecords({
    bool includeDeleted = false,
  }) => Stream.value(
    includeDeleted ? records : records.where((r) => !r.isDeleted).toList(),
  );

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForDate(
    String date, {
    bool includeDeleted = false,
  }) async => records.where((r) => r.date == date).toList();

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForSubject(
    String subjectId, {
    bool includeDeleted = false,
  }) async => records.where((r) => r.subjectId == subjectId).toList();

  @override
  Future<void> saveAttendanceRecord(AttendanceRecordEntity record) async {
    records.removeWhere((r) => r.id == record.id);
    records.add(record);
  }

  @override
  Future<void> saveAttendanceRecords(
    List<AttendanceRecordEntity> newRecords,
  ) async {
    for (final r in newRecords) {
      records.removeWhere((existing) => existing.id == r.id);
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
  Future<List<LegacyAttendanceEntity>> getLegacyAttendance({
    bool includeDeleted = false,
  }) async {
    return includeDeleted ? legacy : legacy.where((l) => !l.isDeleted).toList();
  }

  @override
  Stream<List<LegacyAttendanceEntity>> watchLegacyAttendance({
    bool includeDeleted = false,
  }) => Stream.value(
    includeDeleted ? legacy : legacy.where((l) => !l.isDeleted).toList(),
  );

  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceEntity record) async {
    legacy.removeWhere((l) => l.id == record.id);
    legacy.add(record);
  }

  @override
  Future<void> saveLegacyAttendances(
    List<LegacyAttendanceEntity> newRecords,
  ) async {
    for (final l in newRecords) {
      legacy.removeWhere((existing) => existing.id == l.id);
      legacy.add(l);
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
    records = records
        .map((r) => r.copyWith(deletedAt: DateTime.now()))
        .toList();
    legacy = legacy.map((l) => l.copyWith(deletedAt: DateTime.now())).toList();
  }
}

class FakeNotesRepo implements NotesRepository {
  List<NoteEntity> notes = [];

  @override
  Future<List<NoteEntity>> getNotes() async => notes;

  @override
  Stream<List<NoteEntity>> watchNotes() => Stream.value(notes);

  @override
  Future<NoteEntity?> getNoteById(String id) async => notes
      .cast<NoteEntity?>()
      .firstWhere((n) => n?.id == id, orElse: () => null);

  @override
  Future<void> saveNote(NoteEntity note) async {
    notes.removeWhere((n) => n.id == note.id);
    notes.add(note);
  }

  @override
  Future<void> saveNotes(List<NoteEntity> newNotes) async {
    for (final n in newNotes) {
      notes.removeWhere((existing) => existing.id == n.id);
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

// In-memory fake Hive Box for snapshot testing
class FakeBox implements Box {
  final Map<dynamic, dynamic> storage = {};

  @override
  dynamic get(key, {defaultValue}) =>
      storage.containsKey(key) ? storage[key] : defaultValue;

  @override
  Future<void> put(key, value) async {
    storage[key] = value;
  }

  @override
  Future<void> delete(key) async {
    storage.remove(key);
  }

  @override
  Future<int> clear() async {
    final count = storage.length;
    storage.clear();
    return count;
  }

  @override
  bool containsKey(key) => storage.containsKey(key);

  @override
  Iterable get keys => storage.keys;

  @override
  Iterable get values => storage.values;

  @override
  Map<dynamic, dynamic> toMap() => Map.from(storage);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BackupService Unit Tests', () {
    late FakeSettingsRepo settingsRepo;
    late FakeSubjectRepo subjectRepo;
    late FakeTimetableRepo timetableRepo;
    late FakeAttendanceRepo attendanceRepo;
    late FakeNotesRepo notesRepo;
    late FakeBox settingsBox;
    late BackupService backupService;

    setUp(() {
      settingsRepo = FakeSettingsRepo();
      subjectRepo = FakeSubjectRepo();
      timetableRepo = FakeTimetableRepo();
      attendanceRepo = FakeAttendanceRepo();
      notesRepo = FakeNotesRepo();
      settingsBox = FakeBox();

      backupService = BackupService(
        settingsRepository: settingsRepo,
        subjectRepository: subjectRepo,
        timetableRepository: timetableRepo,
        attendanceRepository: attendanceRepo,
        notesRepository: notesRepo,
        settingsBoxOverride: settingsBox,
      );
    });

    test(
      'parseBackup with empty string or null fails with 5MB/empty safety limit message',
      () {
        final res1 = backupService.parseBackup('');
        expect(res1.isValid, isFalse);
        expect(
          res1.error,
          'Backup file is empty or exceeds the 5 MB safety limit.',
        );

        final res2 = backupService.parseBackup(null);
        expect(res2.isValid, isFalse);
        expect(
          res2.error,
          'Backup file is empty or exceeds the 5 MB safety limit.',
        );
      },
    );

    test('parseBackup exceeding 5MB fails with safety limit message', () {
      // 5MB + 1 byte
      final bigBytes = Uint8List(5 * 1024 * 1024 + 1);
      final res = backupService.parseBackup(bigBytes);
      expect(res.isValid, isFalse);
      expect(
        res.error,
        'Backup file is empty or exceeds the 5 MB safety limit.',
      );
    });

    test('parseBackup with malformed JSON fails with valid JSON message', () {
      final res = backupService.parseBackup('{ invalid json: here ');
      expect(res.isValid, isFalse);
      expect(
        res.error,
        'This file is not valid JSON. Existing data was not changed.',
      );
    });

    test(
      'parseBackup with wrong format identifier fails with format error message',
      () {
        final raw = jsonEncode({
          'format': 'unknown-format',
          'schemaVersion': 2,
          'data': {},
        });
        final res = backupService.parseBackup(raw);
        expect(res.isValid, isFalse);
        expect(
          res.error,
          'This is not a College Attendance Tracker backup. Existing data was not changed.',
        );
      },
    );

    test(
      'parseBackup with newer schemaVersion fails with newer version error message',
      () {
        final raw = jsonEncode({
          'format': 'college-attendance-tracker-backup',
          'schemaVersion': 99,
          'data': {},
        });
        final res = backupService.parseBackup(raw);
        expect(res.isValid, isFalse);
        expect(
          res.error,
          'This backup is from a newer app version and cannot be restored safely.',
        );
      },
    );

    test('parseBackup parses valid V2 backup and extracts summary counts', () {
      final now = DateTime.now();
      final validV2 = {
        'format': 'college-attendance-tracker-backup',
        'schemaVersion': 2,
        'exportedAt': now.toIso8601String(),
        'data': {
          'schemaVersion': 2,
          'name': 'Suklal Gorai',
          'programName': 'B.Tech CSE',
          'courseName': 'Semester 6',
          'startDate': '2026-01-15',
          'minPercent': 80.0,
          'classDays': [1, 2, 3, 4, 5],
          'timetable': {
            '1': [
              {
                'id': 'sess-1',
                'subjectId': 'sub-math',
                'label': 'Mathematics',
                'dayOfWeek': 1,
                'active': true,
              },
            ],
          },
          'subjects': [
            {
              'id': 'sub-math',
              'name': 'Mathematics',
              'color': '#3B82F6',
              'active': true,
              'createdAt': now.toIso8601String(),
              'updatedAt': now.toIso8601String(),
            },
          ],
          'attendanceRecords': [
            {
              'id': 'rec-1',
              'date': '2026-02-01',
              'subjectId': 'sub-math',
              'sessionId': 'sess-1',
              'status': 'PRESENT',
            },
          ],
          'legacyAttendance': [
            {
              'id': 'legacy-2026-01-20',
              'date': '2026-01-20',
              'held': 4,
              'attended': 3,
            },
          ],
          'notes': [
            {'id': 'note-1', 'content': 'Study Calculus tonight'},
          ],
        },
      };

      final res = backupService.parseBackup(jsonEncode(validV2));
      expect(res.isValid, isTrue);
      expect(res.summary, isNotNull);
      expect(res.summary!.subjectsCount, 1);
      expect(res.summary!.sessionsCount, 1);
      expect(res.summary!.attendanceRecordsCount, 1);
      expect(res.summary!.legacyRecordsCount, 1);
      expect(res.summary!.notesCount, 1);
      expect(res.summary!.quarantinedCount, 0);
    });

    test(
      'parseBackup handles V1 legacy daily records and string timetable sessions',
      () {
        final v1 = {
          'format': 'college-attendance-tracker-backup',
          'schemaVersion': 1,
          'data': {
            'records': {
              '2026-01-10': {'held': 2, 'attended': 2},
              '2026-01-11': {'held': 3, 'attended': 1},
            },
            'timetable': {
              '1': ['Algorithms', 'Data Structures'],
            },
            'subjects': [],
          },
        };

        final res = backupService.parseBackup(jsonEncode(v1));
        expect(res.isValid, isTrue);
        expect(res.summary, isNotNull);
        expect(res.summary!.legacyRecordsCount, 2);
        expect(res.summary!.sessionsCount, 2);
        expect(res.summary!.subjectsCount, 2); // synthesized legacy subjects
      },
    );

    test(
      'createBackup exports current application state into validated envelope',
      () async {
        final now = DateTime.now();
        await settingsRepo.saveSettings(
          const UserSettingsEntity(name: 'Alice', programName: 'BCA'),
        );
        await subjectRepo.saveSubject(
          SubjectEntity(
            id: 'sub-1',
            name: 'Operating Systems',
            createdAt: now,
            updatedAt: now,
          ),
        );

        final exportMap = await backupService.createBackup();
        expect(exportMap['format'], 'college-attendance-tracker-backup');
        expect(exportMap['schemaVersion'], 2);
        expect(exportMap['data'], isA<Map<String, dynamic>>());

        final exportData = exportMap['data'] as Map<String, dynamic>;
        expect(exportData['name'], 'Alice');
        expect(exportData['programName'], 'BCA');
        expect((exportData['subjects'] as List).length, 1);

        final jsonStr = await backupService.createBackupJsonString();
        expect(jsonStr.contains('Operating Systems'), isTrue);
      },
    );

    test(
      'restoreBackup saves pre-restore safety snapshot and restores all data',
      () async {
        final now = DateTime.now();
        // Current state before restore
        await settingsRepo.saveSettings(
          const UserSettingsEntity(name: 'Before User'),
        );

        // New data to restore
        final backupData = {
          'name': 'Restored User',
          'programName': 'B.Tech IT',
          'minPercent': 85.0,
          'classDays': [1, 2, 3, 4],
          'subjects': [
            {
              'id': 'sub-restored',
              'name': 'Cloud Computing',
              'createdAt': now.toIso8601String(),
              'updatedAt': now.toIso8601String(),
            },
          ],
          'timetable': {
            '1': [
              {
                'id': 'sess-restored',
                'subjectId': 'sub-restored',
                'label': 'Cloud Computing',
                'dayOfWeek': 1,
              },
            ],
          },
          'attendanceRecords': [
            {
              'id': 'rec-restored',
              'date': '2026-03-01',
              'subjectId': 'sub-restored',
              'sessionId': 'sess-restored',
              'status': 'PRESENT',
            },
          ],
          'notes': [
            {'id': 'note-restored', 'content': 'Prepare presentation'},
          ],
        };

        final result = await backupService.restoreBackup(backupData);
        expect(result.ok, isTrue);

        // Verify pre-restore snapshot was stored in settingsBox
        final preRestoreKeys = settingsBox.keys.where(
          (k) => k.toString().startsWith('pre_restore_'),
        );
        expect(preRestoreKeys.isNotEmpty, isTrue);

        // Verify restored entities
        final updatedSettings = await settingsRepo.getSettings();
        expect(updatedSettings.name, 'Restored User');
        expect(updatedSettings.programName, 'B.Tech IT');
        expect(updatedSettings.minPercent, 85.0);
        expect(updatedSettings.classDays, [1, 2, 3, 4]);

        final updatedSubjects = await subjectRepo.getSubjects();
        expect(updatedSubjects.any((s) => s.name == 'Cloud Computing'), isTrue);

        final updatedTimetable = await timetableRepo.getTimetable();
        expect(updatedTimetable[1]?.first.label, 'Cloud Computing');

        final updatedRecords = await attendanceRepo.getAttendanceRecords();
        expect(updatedRecords.any((r) => r.id == 'rec-restored'), isTrue);

        final updatedNotes = await notesRepo.getNotes();
        expect(
          updatedNotes.any((n) => n.content == 'Prepare presentation'),
          isTrue,
        );
      },
    );

    test(
      'resetAllAttendanceAndNotes clears attendance & notes but preserves subjects and settings',
      () async {
        final now = DateTime.now();
        await settingsRepo.saveSettings(
          const UserSettingsEntity(name: 'Preserved Profile'),
        );
        await subjectRepo.saveSubject(
          SubjectEntity(
            id: 'sub-preserve',
            name: 'Preserved Subject',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await attendanceRepo.saveAttendanceRecord(
          AttendanceRecordEntity(
            id: 'rec-to-clear',
            date: '2026-02-15',
            sessionId: 'sess-1',
            status: AttendanceStatus.present,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await notesRepo.saveNote(
          NoteEntity(id: 'note-to-clear', content: 'Clear me', createdAt: now),
        );

        final success = await backupService.resetAllAttendanceAndNotes();
        expect(success, isTrue);

        // Verify safety snapshot taken
        final preRestoreKeys = settingsBox.keys.where(
          (k) => k.toString().startsWith('pre_restore_'),
        );
        expect(preRestoreKeys.isNotEmpty, isTrue);

        // Verify attendance records are soft-deleted
        final activeRecords = await attendanceRepo.getAttendanceRecords(
          includeDeleted: false,
        );
        expect(activeRecords.isEmpty, isTrue);

        // Verify notes are cleared
        final notes = await notesRepo.getNotes();
        expect(notes.isEmpty, isTrue);

        // Verify subjects and settings remain untouched
        final settings = await settingsRepo.getSettings();
        expect(settings.name, 'Preserved Profile');
        final subjects = await subjectRepo.getSubjects();
        expect(subjects.any((s) => s.name == 'Preserved Subject'), isTrue);
      },
    );

    test(
      'restoreBackup preserves DailyFlow settings and savePreRestoreBackup prunes snapshots to max 3',
      () async {
        await settingsRepo.saveSettings(
          const UserSettingsEntity(
            name: 'Existing User',
            dailyFlowMorningTime: '06:30',
            dailyFlowEveningTime: '21:45',
            dailyFlowSmartRemindersEnabled: false,
            dailyFlowFollowUpsEnabled: false,
            dailyFlowPlanningHorizonDays: 14,
          ),
        );

        // Older backup map without dailyFlow* fields
        final result = await backupService.restoreBackup({
          'name': 'Restored Name',
          'minPercent': 80,
          'classDays': [1, 2, 3, 4, 5],
        });
        expect(result.ok, isTrue);

        final restoredSettings = await settingsRepo.getSettings();
        expect(restoredSettings.name, 'Restored Name');
        expect(restoredSettings.dailyFlowMorningTime, '06:30');
        expect(restoredSettings.dailyFlowEveningTime, '21:45');
        expect(restoredSettings.dailyFlowSmartRemindersEnabled, isFalse);
        expect(restoredSettings.dailyFlowFollowUpsEnabled, isFalse);
        expect(restoredSettings.dailyFlowPlanningHorizonDays, 14);

        // Create multiple pre-restore snapshots and ensure pruning caps at 3
        for (var i = 0; i < 5; i++) {
          await backupService.savePreRestoreBackup();
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
        final remainingSnapshots = settingsBox.keys
            .whereType<String>()
            .where((k) => k.startsWith('pre_restore_'))
            .toList();
        expect(remainingSnapshots.length, lessThanOrEqualTo(3));
      },
    );
  });
}
