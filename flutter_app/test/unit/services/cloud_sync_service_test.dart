import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/services/network_connectivity_service.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:flutter_app/features/auth/domain/entities/auth_user_entity.dart';
import 'package:flutter_app/features/notes/domain/entities/note_entity.dart';
import 'package:flutter_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_app/features/settings/domain/services/backup_service.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';
import 'package:flutter_app/features/subjects/domain/repositories/subject_repository.dart';
import 'package:flutter_app/features/sync/data/datasources/remote_sync_datasource_impl.dart';
import 'package:flutter_app/features/sync/domain/models/sync_state.dart';
import 'package:flutter_app/features/sync/domain/services/cloud_sync_service.dart';
import 'package:flutter_app/features/timetable/domain/entities/timetable_session_entity.dart';
import 'package:flutter_app/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

// In-memory fake repositories for test isolation
class FakeSettingsRepo implements SettingsRepository {
  UserSettingsEntity settings = const UserSettingsEntity(name: 'Initial Student');

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
  Future<Map<int, List<TimetableSessionEntity>>> getTimetable({bool includeDeleted = false}) async =>
      timetable;

  @override
  Stream<Map<int, List<TimetableSessionEntity>>> watchTimetable({bool includeDeleted = false}) =>
      Stream.value(timetable);

  @override
  Future<void> addSession(int dayOfWeek, String subjectId, {String? label}) async {}

  @override
  Future<void> removeSession(int dayOfWeek, String sessionId) async {}

  @override
  Future<void> clearTimetable() async {
    timetable.clear();
  }

  @override
  Future<void> saveTimetable(Map<int, List<TimetableSessionEntity>> newTimetable) async {
    timetable = Map.from(newTimetable);
  }
}

class FakeAttendanceRepo implements AttendanceRepository {
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
  Future<List<LegacyAttendanceEntity>> getLegacyAttendance({bool includeDeleted = false}) async =>
      includeDeleted ? legacy : legacy.where((l) => !l.isDeleted).toList();

  @override
  Stream<List<LegacyAttendanceEntity>> watchLegacyAttendance({bool includeDeleted = false}) =>
      Stream.value(includeDeleted ? legacy : legacy.where((l) => !l.isDeleted).toList());

  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceEntity record) async {
    legacy.removeWhere((l) => l.id == record.id);
    legacy.add(record);
  }

  @override
  Future<void> saveLegacyAttendances(List<LegacyAttendanceEntity> newRecords) async {
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
    records = records.map((r) => r.copyWith(deletedAt: DateTime.now())).toList();
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

class FakeBox implements Box {
  final Map<dynamic, dynamic> storage = {};

  @override
  dynamic get(key, {defaultValue}) => storage.containsKey(key) ? storage[key] : defaultValue;

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CloudSyncService Unit Tests', () {
    late FakeSettingsRepo settingsRepo;
    late FakeSubjectRepo subjectRepo;
    late FakeTimetableRepo timetableRepo;
    late FakeAttendanceRepo attendanceRepo;
    late FakeNotesRepo notesRepo;
    late FakeBox settingsBox;
    late BackupService backupService;
    late DefaultRemoteSyncDataSource remoteDataSource;
    late FakeNetworkConnectivityService connectivityService;
    late CloudSyncService syncService;

    final authenticatedUser = const AuthUserEntity(
      id: 'student_123',
      email: 'student@college.edu',
      displayName: 'Alice Student',
      isGuest: false,
    );

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

      remoteDataSource = DefaultRemoteSyncDataSource();
      connectivityService = FakeNetworkConnectivityService(initialOnline: true);

      syncService = CloudSyncService(
        remoteDataSource: remoteDataSource,
        backupService: backupService,
        connectivityService: connectivityService,
      );
    });

    tearDown(() {
      syncService.dispose();
      connectivityService.dispose();
    });

    test('Guest User completely bypasses remote synchronization', () async {
      syncService.updateUser(AuthUserEntity.guest());

      // 1. flushToCloud for guest
      final flushResult = await syncService.flushToCloud();
      expect(flushResult.isSuccess, isTrue);
      expect(flushResult.skippedGuest, isTrue);
      expect(remoteDataSource.getRawRemoteUser('guest'), isNull);

      // 2. loadUserData for guest
      final loadResult = await syncService.loadUserData('guest');
      expect(loadResult.isSuccess, isTrue);
      expect(loadResult.warnings, isEmpty);
      expect(syncService.currentState.status, SyncStatus.idle);

      // 3. scheduleDebouncedSync for guest should not trigger pending change
      syncService.scheduleDebouncedSync();
      expect(syncService.currentState.hasPendingChanges, isFalse);
    });

    test('flushToCloud synchronizes local state to remote and updates status to synced', () async {
      syncService.updateUser(authenticatedUser);

      // Add a subject locally
      await subjectRepo.saveSubject(SubjectEntity(
        id: 'sub-math',
        name: 'Mathematics',
        createdAt: DateTime.parse('2026-11-20T10:00:00Z'),
        updatedAt: DateTime.parse('2026-11-20T10:00:00Z'),
      ));

      final result = await syncService.flushToCloud();
      expect(result.isSuccess, isTrue);
      expect(syncService.currentState.status, SyncStatus.synced);
      expect(syncService.currentState.lastSyncedAt, isNotNull);
      expect(syncService.currentState.hasPendingChanges, isFalse);

      // Verify remote document has subject and metadata
      final cloudDoc = remoteDataSource.getRawRemoteUser('student_123');
      expect(cloudDoc, isNotNull);
      expect(cloudDoc!['email'], 'student@college.edu');
      expect(cloudDoc['displayName'], 'Alice Student');
      final cloudSubjects = (cloudDoc['subjects'] as List).cast<Map>();
      expect(cloudSubjects.any((s) => s['id'] == 'sub-math'), isTrue);
    });

    test('loadUserData performs LWW merge and restores cloud entities locally', () async {
      syncService.updateUser(authenticatedUser);

      // Seed cloud with a Physics subject
      remoteDataSource.seedRemoteUser('student_123', {
        'schemaVersion': 2,
        'name': 'Cloud Name',
        'subjects': [
          {
            'id': 'sub-physics',
            'name': 'Physics 101',
            'color': '#0000FF',
            'active': true,
            'createdAt': '2026-11-21T10:00:00Z',
            'updatedAt': '2026-11-21T10:00:00Z',
          }
        ],
        'updatedAt': '2026-11-21T10:00:00Z',
      });

      final loadResult = await syncService.loadUserData('student_123');
      expect(loadResult.isSuccess, isTrue);
      expect(loadResult.warnings, isEmpty);

      // Verify subject is now present in local repository
      final localSubjects = await subjectRepo.getSubjects();
      expect(localSubjects.any((s) => s.id == 'sub-physics'), isTrue);
      expect(localSubjects.firstWhere((s) => s.id == 'sub-physics').name, 'Physics 101');
    });

    test('Offline error queues pending changes and reports warning status', () async {
      syncService.updateUser(authenticatedUser);
      connectivityService.setOnline(false);

      final result = await syncService.flushToCloud();
      expect(result.isSuccess, isFalse);
      expect(result.isOffline, isTrue);
      expect(syncService.currentState.status, SyncStatus.offlineWarning);
      expect(syncService.currentState.hasPendingChanges, isTrue);

      // loadUserData during offline returns local data with warning
      final loadResult = await syncService.loadUserData('student_123');
      expect(loadResult.isSuccess, isTrue);
      expect(loadResult.isOfflineFallback, isTrue);
      expect(loadResult.warnings, contains('Cloud data is currently unavailable; using local data.'));
    });

    test('Reconnection automatically triggers flush for queued changes', () async {
      syncService.updateUser(authenticatedUser);

      // Start offline and attempt flush -> queue changes
      connectivityService.setOnline(false);
      await syncService.flushToCloud();
      expect(syncService.currentState.hasPendingChanges, isTrue);

      // Transition connection to online
      connectivityService.setOnline(true);
      await Future.delayed(const Duration(milliseconds: 50));

      // Automatic sync should have completed
      expect(syncService.currentState.status, SyncStatus.synced);
      expect(syncService.currentState.hasPendingChanges, isFalse);
    });

    test('LWW Conflict Resolution preserves soft-deleted tombstones', () async {
      syncService.updateUser(authenticatedUser);

      // Cloud has active subject from earlier
      remoteDataSource.seedRemoteUser('student_123', {
        'schemaVersion': 2,
        'subjects': [
          {
            'id': 'sub-chemistry',
            'name': 'Chemistry',
            'active': true,
            'createdAt': '2026-11-19T10:00:00Z',
            'updatedAt': '2026-11-19T10:00:00Z',
            'deletedAt': null,
          }
        ],
        'updatedAt': '2026-11-19T10:00:00Z',
      });

      // Local has tombstone with newer updatedAt
      await subjectRepo.saveSubject(SubjectEntity(
        id: 'sub-chemistry',
        name: 'Chemistry',
        createdAt: DateTime.parse('2026-11-19T10:00:00Z'),
        updatedAt: DateTime.parse('2026-11-22T10:00:00Z'),
        deletedAt: DateTime.parse('2026-11-22T10:00:00Z'),
      ));

      await syncService.flushToCloud();

      // Cloud document must now contain the tombstone (deletedAt != null)
      final cloudDoc = remoteDataSource.getRawRemoteUser('student_123');
      final cloudSub = (cloudDoc!['subjects'] as List)
          .cast<Map>()
          .firstWhere((s) => s['id'] == 'sub-chemistry');
      expect(cloudSub['deletedAt'], isNotNull);
    });

    test('scheduleDebouncedSync sets hasPendingChanges and can be cancelled by flushToCloud', () async {
      syncService.updateUser(authenticatedUser);

      syncService.scheduleDebouncedSync();
      expect(syncService.currentState.hasPendingChanges, isTrue);

      // Immediate flush executes and clears pending
      final flushResult = await syncService.flushToCloud();
      expect(flushResult.isSuccess, isTrue);
      expect(syncService.currentState.hasPendingChanges, isFalse);
    });
  });
}
