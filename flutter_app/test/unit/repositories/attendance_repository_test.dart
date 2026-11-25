import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:flutter_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:flutter_app/features/attendance/data/models/legacy_attendance_model.dart';
import 'package:flutter_app/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';

class FakeAttendanceLocalDataSource implements AttendanceLocalDataSource {
  final List<AttendanceRecordModel> _records = [];
  final List<LegacyAttendanceModel> _legacy = [];

  final _recordsController =
      StreamController<List<AttendanceRecordModel>>.broadcast();
  final _legacyController =
      StreamController<List<LegacyAttendanceModel>>.broadcast();

  void _notifyRecords() => _recordsController.add(List.unmodifiable(_records));
  void _notifyLegacy() => _legacyController.add(List.unmodifiable(_legacy));

  @override
  Future<List<AttendanceRecordModel>> getAttendanceRecords() async =>
      List.from(_records);

  @override
  Stream<List<AttendanceRecordModel>> watchAttendanceRecords() async* {
    yield List.from(_records);
    yield* _recordsController.stream;
  }

  @override
  Future<void> saveAttendanceRecord(AttendanceRecordModel record) async {
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      _records[index] = record;
    } else {
      _records.add(record);
    }
    _notifyRecords();
  }

  @override
  Future<void> saveAttendanceRecords(
    List<AttendanceRecordModel> records,
  ) async {
    _records.clear();
    _records.addAll(records);
    _notifyRecords();
  }

  @override
  Future<void> deleteAttendanceRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    _notifyRecords();
  }

  @override
  Future<AttendanceRecordModel?> getRecordById(String id) async {
    final match = _records.where((r) => r.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<List<LegacyAttendanceModel>> getLegacyAttendance() async =>
      List.from(_legacy);

  @override
  Stream<List<LegacyAttendanceModel>> watchLegacyAttendance() async* {
    yield List.from(_legacy);
    yield* _legacyController.stream;
  }

  @override
  Future<void> saveLegacyAttendance(LegacyAttendanceModel record) async {
    final index = _legacy.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      _legacy[index] = record;
    } else {
      _legacy.add(record);
    }
    _notifyLegacy();
  }

  @override
  Future<void> saveLegacyAttendances(
    List<LegacyAttendanceModel> records,
  ) async {
    _legacy.clear();
    _legacy.addAll(records);
    _notifyLegacy();
  }

  @override
  Future<void> deleteLegacyAttendance(String id) async {
    _legacy.removeWhere((r) => r.id == id);
    _notifyLegacy();
  }

  @override
  Future<LegacyAttendanceModel?> getLegacyRecordById(String id) async {
    final match = _legacy.where((r) => r.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<void> clearAllAttendanceHistory() async {
    _records.clear();
    _legacy.clear();
    _notifyRecords();
    _notifyLegacy();
  }
}

void main() {
  group('AttendanceRepositoryImpl Unit Tests', () {
    late FakeAttendanceLocalDataSource fakeDataSource;
    late AttendanceRepositoryImpl repository;
    final now = DateTime(2026, 3, 1, 9, 0);

    setUp(() {
      fakeDataSource = FakeAttendanceLocalDataSource();
      repository = AttendanceRepositoryImpl(localDataSource: fakeDataSource);
    });

    test(
      'saveAttendanceRecord and getAttendanceRecords excluding deleted by default',
      () async {
        final rec1 = AttendanceRecordEntity(
          id: 'r1',
          date: '2026-03-01',
          subjectId: 'sub-1',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        );

        final rec2 = AttendanceRecordEntity(
          id: 'r2',
          date: '2026-03-01',
          subjectId: 'sub-2',
          sessionId: 's2',
          status: AttendanceStatus.absent,
          createdAt: now,
          updatedAt: now,
          deletedAt: now,
        );

        await repository.saveAttendanceRecord(rec1);
        await repository.saveAttendanceRecord(rec2);

        final active = await repository.getAttendanceRecords();
        expect(active.length, 1);
        expect(active.first.id, 'r1');

        final all = await repository.getAttendanceRecords(includeDeleted: true);
        expect(all.length, 2);
      },
    );

    test('getRecordsForDate filters records matching date', () async {
      final r1 = AttendanceRecordEntity(
        id: 'r1',
        date: '2026-03-01',
        subjectId: 'sub-1',
        sessionId: 's1',
        status: AttendanceStatus.present,
        createdAt: now,
        updatedAt: now,
      );

      final r2 = AttendanceRecordEntity(
        id: 'r2',
        date: '2026-03-02',
        subjectId: 'sub-1',
        sessionId: 's2',
        status: AttendanceStatus.present,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveAttendanceRecords([r1, r2]);

      final date1Records = await repository.getRecordsForDate('2026-03-01');
      expect(date1Records.length, 1);
      expect(date1Records.first.id, 'r1');
    });

    test('getRecordsForSubject filters records matching subjectId', () async {
      final r1 = AttendanceRecordEntity(
        id: 'r1',
        date: '2026-03-01',
        subjectId: 'math',
        sessionId: 's1',
        status: AttendanceStatus.present,
        createdAt: now,
        updatedAt: now,
      );

      final r2 = AttendanceRecordEntity(
        id: 'r2',
        date: '2026-03-01',
        subjectId: 'physics',
        sessionId: 's2',
        status: AttendanceStatus.present,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveAttendanceRecords([r1, r2]);

      final mathRecords = await repository.getRecordsForSubject('math');
      expect(mathRecords.length, 1);
      expect(mathRecords.first.id, 'r1');
    });

    test(
      'deleteAttendanceRecord and restoreAttendanceRecord semantics',
      () async {
        final r1 = AttendanceRecordEntity(
          id: 'rec-del',
          date: '2026-03-01',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        );

        await repository.saveAttendanceRecord(r1);
        await repository.deleteAttendanceRecord('rec-del');

        expect((await repository.getAttendanceRecords()).isEmpty, isTrue);

        final deletedList = await repository.getAttendanceRecords(
          includeDeleted: true,
        );
        expect(deletedList.length, 1);
        expect(deletedList.first.isDeleted, isTrue);

        await repository.restoreAttendanceRecord('rec-del');
        final restoredList = await repository.getAttendanceRecords();
        expect(restoredList.length, 1);
        expect(restoredList.first.isDeleted, isFalse);
      },
    );

    test('hardDeleteAttendanceRecord permanently removes record', () async {
      final r1 = AttendanceRecordEntity(
        id: 'rec-hard',
        date: '2026-03-01',
        sessionId: 's1',
        status: AttendanceStatus.present,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveAttendanceRecord(r1);
      await repository.hardDeleteAttendanceRecord('rec-hard');

      expect(
        (await repository.getAttendanceRecords(includeDeleted: true)).isEmpty,
        isTrue,
      );
    });

    test(
      'Legacy attendance CRUD, soft delete, restore, and hard delete',
      () async {
        final leg1 = LegacyAttendanceEntity(
          id: 'leg-1',
          date: '2026-02-01',
          held: 5,
          attended: 4,
          createdAt: now,
          updatedAt: now,
        );

        await repository.saveLegacyAttendance(leg1);
        expect((await repository.getLegacyAttendance()).length, 1);

        await repository.deleteLegacyAttendance('leg-1');
        expect((await repository.getLegacyAttendance()).isEmpty, isTrue);
        expect(
          (await repository.getLegacyAttendance(includeDeleted: true)).length,
          1,
        );

        await repository.restoreLegacyAttendance('leg-1');
        expect((await repository.getLegacyAttendance()).length, 1);

        await repository.hardDeleteLegacyAttendance('leg-1');
        expect(
          (await repository.getLegacyAttendance(includeDeleted: true)).isEmpty,
          isTrue,
        );
      },
    );

    test(
      'clearAllAttendanceHistory empties both session and legacy records',
      () async {
        await repository.saveAttendanceRecord(
          AttendanceRecordEntity(
            id: 'r1',
            date: '2026-03-01',
            sessionId: 's1',
            status: AttendanceStatus.present,
            createdAt: now,
            updatedAt: now,
          ),
        );

        await repository.saveLegacyAttendance(
          LegacyAttendanceEntity(
            id: 'l1',
            date: '2026-02-01',
            held: 2,
            attended: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );

        expect((await repository.getAttendanceRecords()).length, 1);
        expect((await repository.getLegacyAttendance()).length, 1);

        await repository.clearAllAttendanceHistory();

        expect(
          (await repository.getAttendanceRecords(includeDeleted: true)).isEmpty,
          isTrue,
        );
        expect(
          (await repository.getLegacyAttendance(includeDeleted: true)).isEmpty,
          isTrue,
        );
      },
    );

    test(
      'watchAttendanceRecords and watchLegacyAttendance stream events',
      () async {
        final record = AttendanceRecordEntity(
          id: 'r-stream',
          date: '2026-03-01',
          sessionId: 's1',
          status: AttendanceStatus.present,
          createdAt: now,
          updatedAt: now,
        );

        expectLater(
          repository.watchAttendanceRecords(),
          emitsInOrder([
            [],
            [record],
          ]),
        );

        await pumpEventQueue();
        await repository.saveAttendanceRecord(record);
      },
    );
  });
}
