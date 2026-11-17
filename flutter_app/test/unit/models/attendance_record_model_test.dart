import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';

void main() {
  group('AttendanceRecordModel Serialization Unit Tests', () {
    final now = DateTime(2026, 3, 1, 9, 0);

    test('serializes toMap with Schema V2 structure', () {
      final model = AttendanceRecordModel(
        id: 'att-1',
        date: '2026-03-01',
        subjectId: 'sub-math',
        sessionId: 'daily-2026-03-01',
        status: AttendanceStatus.present,
        createdAt: now,
        updatedAt: now,
      );

      final map = model.toMap();

      expect(map['id'], 'att-1');
      expect(map['date'], '2026-03-01');
      expect(map['subjectId'], 'sub-math');
      expect(map['sessionId'], 'daily-2026-03-01');
      expect(map['status'], 'PRESENT');
      expect(map['createdAt'], now.toIso8601String());
      expect(map['updatedAt'], now.toIso8601String());
      expect(map['deletedAt'], isNull);
    });

    test('deserializes fromMap with valid data', () {
      final map = {
        'id': 'att-2',
        'date': '2026-03-02',
        'subjectId': 'sub-phy',
        'sessionId': 'session-2',
        'status': 'ABSENT',
        'createdAt': '2026-03-02T10:00:00.000',
        'updatedAt': '2026-03-02T11:00:00.000',
        'deletedAt': '2026-03-02T12:00:00.000',
      };

      final model = AttendanceRecordModel.fromMap(map);

      expect(model.id, 'att-2');
      expect(model.date, '2026-03-02');
      expect(model.subjectId, 'sub-phy');
      expect(model.sessionId, 'session-2');
      expect(model.status, AttendanceStatus.absent);
      expect(model.createdAt, DateTime.parse('2026-03-02T10:00:00.000'));
      expect(model.isDeleted, isTrue);
    });

    test('deserializes fromMap with missing fields defensively', () {
      final model = AttendanceRecordModel.fromMap({});

      expect(model.id, '');
      expect(model.date, '');
      expect(model.subjectId, dailySubjectId);
      expect(model.sessionId, '');
      expect(model.status, AttendanceStatus.unmarked);
      expect(model.deletedAt, isNull);
    });

    test('creates model from entity via fromEntity', () {
      final entity = AttendanceRecordEntity(
        id: 'att-3',
        date: '2026-03-03',
        sessionId: 'session-3',
        status: AttendanceStatus.cancelled,
        createdAt: now,
        updatedAt: now,
      );

      final model = AttendanceRecordModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.date, entity.date);
      expect(model.sessionId, entity.sessionId);
      expect(model.status, entity.status);
    });
  });
}
