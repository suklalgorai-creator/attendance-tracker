import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/network_connectivity_service.dart';
import '../../../attendance/domain/entities/attendance_record_entity.dart';
import '../../../attendance/domain/entities/legacy_attendance_entity.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../notes/domain/entities/note_entity.dart';
import '../../../notes/domain/repositories/notes_repository.dart';
import '../../../settings/domain/entities/user_settings_entity.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../../settings/domain/services/backup_service.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../../subjects/domain/repositories/subject_repository.dart';
import '../../../timetable/domain/entities/timetable_session_entity.dart';
import '../../../timetable/domain/repositories/timetable_repository.dart';
import '../../data/datasources/remote_sync_datasource_impl.dart';
import '../../domain/datasources/remote_sync_datasource.dart';
import '../../domain/models/sync_state.dart';
import '../../domain/services/cloud_sync_service.dart';

/// Provider for [RemoteSyncDataSource], defaulting to the offline-safe implementation.
final remoteSyncDataSourceProvider = Provider<RemoteSyncDataSource>((ref) {
  return DefaultRemoteSyncDataSource();
});

/// Provider for [NetworkConnectivityService].
final networkConnectivityServiceProvider =
    Provider<NetworkConnectivityService>((ref) {
  final service = NetworkConnectivityServiceImpl();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for [CloudSyncService], automatically observing current auth state.
/// Safely falls back to an in-memory stub if local Hive boxes are not initialized (e.g. in widget tests).
final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final hasHiveBoxes = DatabaseService.isBoxOpen(DatabaseService.settingsBoxName);

  final BackupService backupService;
  if (hasHiveBoxes) {
    backupService = ref.watch(backupServiceProvider);
  } else {
    backupService = BackupService(
      settingsRepository: _FallbackSettingsRepo(),
      subjectRepository: _FallbackSubjectRepo(),
      timetableRepository: _FallbackTimetableRepo(),
      attendanceRepository: _FallbackAttendanceRepo(),
      notesRepository: _FallbackNotesRepo(),
      settingsBoxOverride: _FallbackBox(),
    );
  }

  final service = CloudSyncService(
    remoteDataSource: ref.watch(remoteSyncDataSourceProvider),
    backupService: backupService,
    connectivityService: ref.watch(networkConnectivityServiceProvider),
  );

  // Synchronize active user
  final authUser = ref.watch(authNotifierProvider).user;
  service.updateUser(authUser);

  ref.onDispose(() => service.dispose());
  return service;
});

/// Reactive stream of sync state changes.
final syncStateStreamProvider = StreamProvider<SyncState>((ref) {
  final service = ref.watch(cloudSyncServiceProvider);
  return service.syncStateStream;
});

// Fallback in-memory stubs used when Hive boxes are not open (e.g. isolated router/widget tests)
class _FallbackSettingsRepo implements SettingsRepository {
  UserSettingsEntity settings = const UserSettingsEntity();
  @override
  Future<UserSettingsEntity> getSettings() async => settings;
  @override
  Stream<UserSettingsEntity> watchSettings() => Stream.value(settings);
  @override
  Future<void> saveSettings(UserSettingsEntity s) async => settings = s;
  @override
  Future<void> resetSettings() async => settings = const UserSettingsEntity();
}

class _FallbackSubjectRepo implements SubjectRepository {
  @override
  Future<List<SubjectEntity>> getSubjects({bool includeDeleted = false}) async => [];
  @override
  Stream<List<SubjectEntity>> watchSubjects({bool includeDeleted = false}) => Stream.value([]);
  @override
  Future<SubjectEntity?> getSubjectById(String id) async => null;
  @override
  Future<void> saveSubject(SubjectEntity subject) async {}
  @override
  Future<void> saveSubjects(List<SubjectEntity> subjects) async {}
  @override
  Future<void> reorderSubjects(List<String> orderedIds) async {}
  @override
  Future<void> deleteSubject(String id) async {}
  @override
  Future<void> restoreSubject(String id) async {}
  @override
  Future<void> hardDeleteSubject(String id) async {}
}

class _FallbackTimetableRepo implements TimetableRepository {
  @override
  Future<Map<int, List<TimetableSessionEntity>>> getTimetable({bool includeDeleted = false}) async => {};
  @override
  Stream<Map<int, List<TimetableSessionEntity>>> watchTimetable({bool includeDeleted = false}) => Stream.value({});
  @override
  Future<void> addSession(int dayOfWeek, String subjectId, {String? label}) async {}
  @override
  Future<void> removeSession(int dayOfWeek, String sessionId) async {}
  @override
  Future<void> clearTimetable() async {}
  @override
  Future<void> saveTimetable(Map<int, List<TimetableSessionEntity>> timetable) async {}
}

class _FallbackAttendanceRepo implements AttendanceRepository {
  @override
  Future<List<AttendanceRecordEntity>> getAttendanceRecords({bool includeDeleted = false}) async => [];
  @override
  Stream<List<AttendanceRecordEntity>> watchAttendanceRecords({bool includeDeleted = false}) => Stream.value([]);
  @override
  Future<List<AttendanceRecordEntity>> getRecordsForDate(String date, {bool includeDeleted = false}) async => [];
  @override
  Future<List<AttendanceRecordEntity>> getRecordsForSubject(String subjectId, {bool includeDeleted = false}) async => [];
  @override
  Future<void> saveAttendanceRecord(AttendanceRecordEntity record) async {}
  @override
  Future<void> saveAttendanceRecords(List<AttendanceRecordEntity> records) async {}
  @override
  Future<void> deleteAttendanceRecord(String id) async {}
  @override
  Future<void> restoreAttendanceRecord(String id) async {}
  @override
  Future<void> hardDeleteAttendanceRecord(String id) async {}
  @override
  Future<List<LegacyAttendanceEntity>> getLegacyAttendance({bool includeDeleted = false}) async => [];
  @override
  Stream<List<LegacyAttendanceEntity>> watchLegacyAttendance({bool includeDeleted = false}) => Stream.value([]);
  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceEntity record) async {}
  @override
  Future<void> saveLegacyAttendances(List<LegacyAttendanceEntity> records) async {}
  @override
  Future<void> deleteLegacyAttendance(String id) async {}
  @override
  Future<void> restoreLegacyAttendance(String id) async {}
  @override
  Future<void> hardDeleteLegacyAttendance(String id) async {}
  @override
  Future<void> clearAllAttendanceHistory() async {}
}

class _FallbackNotesRepo implements NotesRepository {
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

class _FallbackBox implements Box {
  final Map<dynamic, dynamic> _storage = {};
  @override
  dynamic get(key, {defaultValue}) => _storage.containsKey(key) ? _storage[key] : defaultValue;
  @override
  Future<void> put(key, value) async => _storage[key] = value;
  @override
  Future<void> delete(key) async => _storage.remove(key);
  @override
  Future<int> clear() async {
    final c = _storage.length;
    _storage.clear();
    return c;
  }
  @override
  bool containsKey(key) => _storage.containsKey(key);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
