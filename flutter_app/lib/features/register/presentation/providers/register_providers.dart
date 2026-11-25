import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../attendance/domain/entities/attendance_record_entity.dart';
import '../../../attendance/domain/entities/legacy_attendance_entity.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../settings/domain/entities/user_settings_entity.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import 'register_controller.dart';
import 'register_state.dart';

class _NoopAttendanceRepository implements AttendanceRepository {
  @override
  Future<List<AttendanceRecordEntity>> getAttendanceRecords({
    bool includeDeleted = false,
  }) async => [];

  @override
  Stream<List<AttendanceRecordEntity>> watchAttendanceRecords({
    bool includeDeleted = false,
  }) => const Stream.empty();

  @override
  Future<void> saveAttendanceRecord(AttendanceRecordEntity record) async {}

  @override
  Future<void> saveAttendanceRecords(
    List<AttendanceRecordEntity> records,
  ) async {}

  @override
  Future<void> deleteAttendanceRecord(String id) async {}

  @override
  Future<void> restoreAttendanceRecord(String id) async {}

  @override
  Future<void> hardDeleteAttendanceRecord(String id) async {}

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForSubject(
    String subjectId, {
    bool includeDeleted = false,
  }) async => [];

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForDate(
    String date, {
    bool includeDeleted = false,
  }) async => [];

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
  Future<void> clearAllAttendanceHistory() async {}
}

class _NoopSettingsRepository implements SettingsRepository {
  @override
  Future<UserSettingsEntity> getSettings() async => const UserSettingsEntity();

  @override
  Stream<UserSettingsEntity> watchSettings() => const Stream.empty();

  @override
  Future<void> saveSettings(UserSettingsEntity settings) async {}

  @override
  Future<void> resetSettings() async {}
}

final registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, RegisterState>((ref) {
      AttendanceRepository attendanceRepo;
      SettingsRepository? settingsRepo;

      try {
        attendanceRepo = ref.watch(attendanceRepositoryProvider);
      } catch (_) {
        attendanceRepo = _NoopAttendanceRepository();
      }

      try {
        settingsRepo = ref.watch(settingsRepositoryProvider);
      } catch (_) {
        settingsRepo = _NoopSettingsRepository();
      }

      Stream<List<LegacyAttendanceEntity>> safeLegacyStream() {
        try {
          return attendanceRepo.watchLegacyAttendance();
        } catch (_) {
          return const Stream.empty();
        }
      }

      Stream<List<AttendanceRecordEntity>> safeRecordsStream() {
        try {
          return attendanceRepo.watchAttendanceRecords();
        } catch (_) {
          return const Stream.empty();
        }
      }

      Stream<UserSettingsEntity> safeSettingsStream() {
        try {
          return settingsRepo?.watchSettings() ?? const Stream.empty();
        } catch (_) {
          return const Stream.empty();
        }
      }

      return RegisterController(
        attendanceRepository: attendanceRepo,
        settingsRepository: settingsRepo,
        legacyStream: safeLegacyStream(),
        recordsStream: safeRecordsStream(),
        settingsStream: safeSettingsStream(),
      );
    });
