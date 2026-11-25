import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';
import 'package:flutter_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/dashboard_controller.dart';

class FakeAttendanceRepository implements AttendanceRepository {
  final List<AttendanceRecordEntity> savedRecords = [];
  final List<String> deletedRecordIds = [];

  @override
  Future<void> saveAttendanceRecord(AttendanceRecordEntity record) async {
    savedRecords.add(record);
  }

  @override
  Future<void> deleteAttendanceRecord(String id) async {
    deletedRecordIds.add(id);
    savedRecords.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> clearAllAttendanceHistory() async => savedRecords.clear();

  @override
  Future<void> deleteLegacyAttendance(String id) async {}

  @override
  Future<List<AttendanceRecordEntity>> getAttendanceRecords({
    bool includeDeleted = false,
  }) async => List.from(savedRecords);

  @override
  Future<List<LegacyAttendanceEntity>> getLegacyAttendance({
    bool includeDeleted = false,
  }) async => [];

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForDate(
    String date, {
    bool includeDeleted = false,
  }) async => [];

  @override
  Future<List<AttendanceRecordEntity>> getRecordsForSubject(
    String subjectId, {
    bool includeDeleted = false,
  }) async => [];

  @override
  Future<void> hardDeleteAttendanceRecord(String id) async {}

  @override
  Future<void> hardDeleteLegacyAttendance(String id) async {}

  @override
  Future<void> restoreAttendanceRecord(String id) async {}

  @override
  Future<void> restoreLegacyAttendance(String id) async {}

  @override
  Future<void> saveAttendanceRecords(
    List<AttendanceRecordEntity> records,
  ) async => savedRecords.addAll(records);

  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceEntity record) async {}

  @override
  Future<void> saveLegacyAttendances(
    List<LegacyAttendanceEntity> records,
  ) async {}

  @override
  Stream<List<AttendanceRecordEntity>> watchAttendanceRecords({
    bool includeDeleted = false,
  }) => Stream.value(savedRecords);

  @override
  Stream<List<LegacyAttendanceEntity>> watchLegacyAttendance({
    bool includeDeleted = false,
  }) => Stream.value([]);
}

void main() {
  late FakeAttendanceRepository repository;
  late DashboardController controller;

  setUp(() {
    repository = FakeAttendanceRepository();
    controller = DashboardController(repository);
  });

  group('DashboardController Unit Tests', () {
    test(
      'markPresent saves a record with AttendanceStatus.present and updates lastLoggedRecord',
      () async {
        await controller.markPresent('sub_math');

        expect(repository.savedRecords.length, 1);
        final record = repository.savedRecords.first;
        expect(record.subjectId, 'sub_math');
        expect(record.status, AttendanceStatus.present);
        expect(controller.lastLoggedRecord, equals(record));
      },
    );

    test(
      'markAbsent saves a record with AttendanceStatus.absent and updates lastLoggedRecord',
      () async {
        await controller.markAbsent('sub_physics');

        expect(repository.savedRecords.length, 1);
        final record = repository.savedRecords.first;
        expect(record.subjectId, 'sub_physics');
        expect(record.status, AttendanceStatus.absent);
        expect(controller.lastLoggedRecord, equals(record));
      },
    );

    test(
      'undoLastAction removes previously logged record and resets lastLoggedRecord',
      () async {
        await controller.markPresent('sub_chemistry');
        final loggedRecord = controller.lastLoggedRecord;
        expect(loggedRecord, isNotNull);

        final success = await controller.undoLastAction();
        expect(success, isTrue);
        expect(repository.deletedRecordIds, contains(loggedRecord!.id));
        expect(controller.lastLoggedRecord, isNull);
      },
    );

    test(
      'undoLastAction returns false when no record was previously logged',
      () async {
        final success = await controller.undoLastAction();
        expect(success, isFalse);
        expect(repository.deletedRecordIds, isEmpty);
      },
    );
  });
}
