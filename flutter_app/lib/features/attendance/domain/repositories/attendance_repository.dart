import '../entities/attendance_record_entity.dart';
import '../entities/legacy_attendance_entity.dart';

/// Abstract contract for Attendance data operations in Domain layer.
abstract class AttendanceRepository {
  Future<List<AttendanceRecordEntity>> getAttendanceRecords({
    bool includeDeleted = false,
  });
  Stream<List<AttendanceRecordEntity>> watchAttendanceRecords({
    bool includeDeleted = false,
  });
  Future<List<AttendanceRecordEntity>> getRecordsForDate(
    String date, {
    bool includeDeleted = false,
  });
  Future<List<AttendanceRecordEntity>> getRecordsForSubject(
    String subjectId, {
    bool includeDeleted = false,
  });
  Future<void> saveAttendanceRecord(AttendanceRecordEntity record);
  Future<void> saveAttendanceRecords(List<AttendanceRecordEntity> records);
  Future<void> deleteAttendanceRecord(String id);
  Future<void> restoreAttendanceRecord(String id);
  Future<void> hardDeleteAttendanceRecord(String id);

  Future<List<LegacyAttendanceEntity>> getLegacyAttendance({
    bool includeDeleted = false,
  });
  Stream<List<LegacyAttendanceEntity>> watchLegacyAttendance({
    bool includeDeleted = false,
  });
  Future<void> saveLegacyAttendance(LegacyAttendanceEntity record);
  Future<void> saveLegacyAttendances(List<LegacyAttendanceEntity> records);
  Future<void> deleteLegacyAttendance(String id);
  Future<void> restoreLegacyAttendance(String id);
  Future<void> hardDeleteLegacyAttendance(String id);

  Future<void> clearAllAttendanceHistory();
}
