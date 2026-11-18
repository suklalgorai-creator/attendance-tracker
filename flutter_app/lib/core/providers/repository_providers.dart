import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/attendance/data/datasources/attendance_local_datasource.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/entities/attendance_record_entity.dart';
import '../../features/attendance/domain/entities/legacy_attendance_entity.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';

import '../../features/notes/data/datasources/notes_local_datasource.dart';
import '../../features/notes/data/repositories/notes_repository_impl.dart';
import '../../features/notes/domain/entities/note_entity.dart';
import '../../features/notes/domain/repositories/notes_repository.dart';

import '../../features/settings/data/datasources/settings_local_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/entities/user_settings_entity.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';

import '../../features/subjects/data/datasources/subject_local_datasource.dart';
import '../../features/subjects/data/repositories/subject_repository_impl.dart';
import '../../features/subjects/domain/entities/subject_entity.dart';
import '../../features/subjects/domain/repositories/subject_repository.dart';

import '../../features/timetable/data/repositories/timetable_repository_impl.dart';
import '../../features/timetable/domain/entities/timetable_session_entity.dart';
import '../../features/timetable/domain/repositories/timetable_repository.dart';

// ==================== Local Data Sources ====================

final subjectLocalDataSourceProvider = Provider<SubjectLocalDataSource>((ref) {
  return SubjectLocalDataSourceImpl();
});

final attendanceLocalDataSourceProvider = Provider<AttendanceLocalDataSource>((ref) {
  return AttendanceLocalDataSourceImpl();
});

final notesLocalDataSourceProvider = Provider<NotesLocalDataSource>((ref) {
  return NotesLocalDataSourceImpl();
});

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((ref) {
  return SettingsLocalDataSourceImpl();
});

// ==================== Repositories ====================

final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepositoryImpl(
    localDataSource: ref.watch(subjectLocalDataSourceProvider),
  );
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(
    localDataSource: ref.watch(attendanceLocalDataSourceProvider),
  );
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepositoryImpl(
    localDataSource: ref.watch(notesLocalDataSourceProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    localDataSource: ref.watch(settingsLocalDataSourceProvider),
  );
});

// ==================== Reactive Stream Providers ====================

final subjectsStreamProvider = StreamProvider<List<SubjectEntity>>((ref) {
  return ref.watch(subjectRepositoryProvider).watchSubjects();
});

final attendanceRecordsStreamProvider = StreamProvider<List<AttendanceRecordEntity>>((ref) {
  return ref.watch(attendanceRepositoryProvider).watchAttendanceRecords();
});

final legacyAttendanceStreamProvider = StreamProvider<List<LegacyAttendanceEntity>>((ref) {
  return ref.watch(attendanceRepositoryProvider).watchLegacyAttendance();
});

final notesStreamProvider = StreamProvider<List<NoteEntity>>((ref) {
  return ref.watch(notesRepositoryProvider).watchNotes();
});

final settingsStreamProvider = StreamProvider<UserSettingsEntity>((ref) {
  return ref.watch(settingsRepositoryProvider).watchSettings();
});

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepositoryImpl(
    subjectRepository: ref.watch(subjectRepositoryProvider),
  );
});

final timetableStreamProvider = StreamProvider<Map<int, List<TimetableSessionEntity>>>((ref) {
  return ref.watch(timetableRepositoryProvider).watchTimetable();
});
