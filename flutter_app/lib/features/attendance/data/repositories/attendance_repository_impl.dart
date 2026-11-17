import '../../domain/entities/attendance_record_entity.dart';
import '../../domain/entities/legacy_attendance_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_local_datasource.dart';
import '../models/attendance_record_model.dart';
import '../models/legacy_attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceLocalDataSource _localDataSource;

  AttendanceRepositoryImpl({AttendanceLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? AttendanceLocalDataSourceImpl();

  @override
  Future<List<AttendanceRecordEntity>> getAttendanceRecords({bool includeDeleted = false}) async {
    final models = await _localDataSource.getAttendanceRecords();
    if (includeDeleted) {
      return models;
    }
    return models.where((r) => !r.isDeleted).toList();
  }

  @override
  Stream<List<AttendanceRecordEntity>> watchAttendanceRecords({bool includeDeleted = false}) {
    return _localDataSource.watchAttendanceRecords().map((list) {
      if (includeDeleted) {
        return list;
      }
      return list.where((r) => !r.isDeleted).toList();
    });
  }

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForDate(String date, {bool includeDeleted = false}) async {
    final records = await getAttendanceRecords(includeDeleted: includeDeleted);
    return records.where((r) => r.date == date).toList();
  }

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForSubject(String subjectId, {bool includeDeleted = false}) async {
    final records = await getAttendanceRecords(includeDeleted: includeDeleted);
    return records.where((r) => r.subjectId == subjectId).toList();
  }

  @override
  Future<void> saveAttendanceRecord(AttendanceRecordEntity record) async {
    final model = AttendanceRecordModel.fromEntity(record);
    await _localDataSource.saveAttendanceRecord(model);
  }

  @override
  Future<void> saveAttendanceRecords(List<AttendanceRecordEntity> records) async {
    final models = records.map(AttendanceRecordModel.fromEntity).toList();
    await _localDataSource.saveAttendanceRecords(models);
  }

  @override
  Future<void> deleteAttendanceRecord(String id) async {
    // Soft deletion matching React dataModel.js
    final record = await _localDataSource.getRecordById(id);
    if (record != null) {
      final now = DateTime.now();
      final updated = record.copyWith(
        deletedAt: now,
        updatedAt: now,
      );
      await _localDataSource.saveAttendanceRecord(AttendanceRecordModel.fromEntity(updated));
    }
  }

  @override
  Future<void> restoreAttendanceRecord(String id) async {
    final record = await _localDataSource.getRecordById(id);
    if (record != null && record.isDeleted) {
      final updated = record.copyWith(
        clearDeletedAt: true,
        updatedAt: DateTime.now(),
      );
      await _localDataSource.saveAttendanceRecord(AttendanceRecordModel.fromEntity(updated));
    }
  }

  @override
  Future<void> hardDeleteAttendanceRecord(String id) async {
    await _localDataSource.deleteAttendanceRecord(id);
  }

  @override
  Future<List<LegacyAttendanceEntity>> getLegacyAttendance({bool includeDeleted = false}) async {
    final models = await _localDataSource.getLegacyAttendance();
    if (includeDeleted) {
      return models;
    }
    return models.where((r) => !r.isDeleted).toList();
  }

  @override
  Stream<List<LegacyAttendanceEntity>> watchLegacyAttendance({bool includeDeleted = false}) {
    return _localDataSource.watchLegacyAttendance().map((list) {
      if (includeDeleted) {
        return list;
      }
      return list.where((r) => !r.isDeleted).toList();
    });
  }

  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceEntity record) async {
    final model = LegacyAttendanceModel.fromEntity(record);
    await _localDataSource.saveLegacyAttendance(model);
  }

  @override
  Future<void> saveLegacyAttendances(List<LegacyAttendanceEntity> records) async {
    final models = records.map(LegacyAttendanceModel.fromEntity).toList();
    await _localDataSource.saveLegacyAttendances(models);
  }

  @override
  Future<void> deleteLegacyAttendance(String id) async {
    // Soft deletion matching React dataModel.js
    final record = await _localDataSource.getLegacyRecordById(id);
    if (record != null) {
      final now = DateTime.now();
      final updated = record.copyWith(
        deletedAt: now,
        updatedAt: now,
      );
      await _localDataSource.saveLegacyAttendance(LegacyAttendanceModel.fromEntity(updated));
    }
  }

  @override
  Future<void> restoreLegacyAttendance(String id) async {
    final record = await _localDataSource.getLegacyRecordById(id);
    if (record != null && record.isDeleted) {
      final updated = record.copyWith(
        clearDeletedAt: true,
        updatedAt: DateTime.now(),
      );
      await _localDataSource.saveLegacyAttendance(LegacyAttendanceModel.fromEntity(updated));
    }
  }

  @override
  Future<void> hardDeleteLegacyAttendance(String id) async {
    await _localDataSource.deleteLegacyAttendance(id);
  }

  @override
  Future<void> clearAllAttendanceHistory() async {
    await _localDataSource.clearAllAttendanceHistory();
  }
}
