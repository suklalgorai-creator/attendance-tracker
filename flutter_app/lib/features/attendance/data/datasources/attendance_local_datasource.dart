import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/database_service.dart';
import '../models/attendance_record_model.dart';
import '../models/legacy_attendance_model.dart';

abstract class AttendanceLocalDataSource {
  Future<List<AttendanceRecordModel>> getAttendanceRecords();
  Stream<List<AttendanceRecordModel>> watchAttendanceRecords();
  Future<void> saveAttendanceRecord(AttendanceRecordModel record);
  Future<void> saveAttendanceRecords(List<AttendanceRecordModel> records);
  Future<void> deleteAttendanceRecord(String id);
  Future<AttendanceRecordModel?> getRecordById(String id);

  Future<List<LegacyAttendanceModel>> getLegacyAttendance();
  Stream<List<LegacyAttendanceModel>> watchLegacyAttendance();
  Future<void> saveLegacyAttendance(LegacyAttendanceModel record);
  Future<void> saveLegacyAttendances(List<LegacyAttendanceModel> records);
  Future<void> deleteLegacyAttendance(String id);
  Future<LegacyAttendanceModel?> getLegacyRecordById(String id);

  Future<void> clearAllAttendanceHistory();
}

class AttendanceLocalDataSourceImpl implements AttendanceLocalDataSource {
  final Box _recordsBox;
  final Box _legacyBox;

  AttendanceLocalDataSourceImpl({Box? recordsBox, Box? legacyBox})
    : _recordsBox =
          recordsBox ??
          DatabaseService.getBox(DatabaseService.attendanceRecordsBoxName),
      _legacyBox =
          legacyBox ??
          DatabaseService.getBox(DatabaseService.legacyAttendanceBoxName);

  @override
  Future<List<AttendanceRecordModel>> getAttendanceRecords() async {
    try {
      final rawData = _recordsBox.get('items', defaultValue: []);
      if (rawData is List) {
        return rawData
            .map(
              (item) => AttendanceRecordModel.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw CacheException('Failed to load attendance records: $e');
    }
  }

  @override
  Stream<List<AttendanceRecordModel>> watchAttendanceRecords() async* {
    yield await getAttendanceRecords();
    yield* _recordsBox
        .watch(key: 'items')
        .asyncMap((_) => getAttendanceRecords());
  }

  @override
  Future<void> saveAttendanceRecords(
    List<AttendanceRecordModel> records,
  ) async {
    try {
      final list = records.map((r) => r.toMap()).toList();
      await _recordsBox.put('items', list);
    } catch (e) {
      throw CacheException('Failed to save attendance records: $e');
    }
  }

  @override
  Future<void> saveAttendanceRecord(AttendanceRecordModel record) async {
    try {
      final current = await getAttendanceRecords();
      final index = current.indexWhere((r) => r.id == record.id);
      if (index >= 0) {
        current[index] = record;
      } else {
        current.add(record);
      }
      await saveAttendanceRecords(current);
    } catch (e) {
      throw CacheException('Failed to save attendance record: $e');
    }
  }

  @override
  Future<void> deleteAttendanceRecord(String id) async {
    try {
      final current = await getAttendanceRecords();
      current.removeWhere((r) => r.id == id);
      await saveAttendanceRecords(current);
    } catch (e) {
      throw CacheException('Failed to delete attendance record: $e');
    }
  }

  @override
  Future<AttendanceRecordModel?> getRecordById(String id) async {
    try {
      final current = await getAttendanceRecords();
      final match = current.where((r) => r.id == id);
      return match.isNotEmpty ? match.first : null;
    } catch (e) {
      throw CacheException('Failed to get attendance record by id: $e');
    }
  }

  @override
  Future<List<LegacyAttendanceModel>> getLegacyAttendance() async {
    try {
      final rawData = _legacyBox.get('items', defaultValue: []);
      if (rawData is List) {
        return rawData
            .map(
              (item) => LegacyAttendanceModel.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw CacheException('Failed to load legacy attendance: $e');
    }
  }

  @override
  Stream<List<LegacyAttendanceModel>> watchLegacyAttendance() async* {
    yield await getLegacyAttendance();
    yield* _legacyBox
        .watch(key: 'items')
        .asyncMap((_) => getLegacyAttendance());
  }

  @override
  Future<void> saveLegacyAttendances(
    List<LegacyAttendanceModel> records,
  ) async {
    try {
      final list = records.map((r) => r.toMap()).toList();
      await _legacyBox.put('items', list);
    } catch (e) {
      throw CacheException('Failed to save legacy attendance records: $e');
    }
  }

  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceModel record) async {
    try {
      final current = await getLegacyAttendance();
      final index = current.indexWhere((r) => r.id == record.id);
      if (index >= 0) {
        current[index] = record;
      } else {
        current.add(record);
      }
      await saveLegacyAttendances(current);
    } catch (e) {
      throw CacheException('Failed to save legacy attendance record: $e');
    }
  }

  @override
  Future<void> deleteLegacyAttendance(String id) async {
    try {
      final current = await getLegacyAttendance();
      current.removeWhere((r) => r.id == id);
      await saveLegacyAttendances(current);
    } catch (e) {
      throw CacheException('Failed to delete legacy attendance record: $e');
    }
  }

  @override
  Future<LegacyAttendanceModel?> getLegacyRecordById(String id) async {
    try {
      final current = await getLegacyAttendance();
      final match = current.where((r) => r.id == id);
      return match.isNotEmpty ? match.first : null;
    } catch (e) {
      throw CacheException('Failed to get legacy record by id: $e');
    }
  }

  @override
  Future<void> clearAllAttendanceHistory() async {
    try {
      await _recordsBox.put('items', []);
      await _legacyBox.put('items', []);
    } catch (e) {
      throw CacheException('Failed to clear attendance history: $e');
    }
  }
}
