import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_record_entity.dart';
import 'package:flutter_app/features/attendance/domain/entities/attendance_status.dart';

void main() {
  group('AttendanceRecordEntity & AttendanceStatus Unit Tests', () {
    final now = DateTime(2026, 3, 1, 9, 30);

    test('AttendanceStatus values and helpers match Schema V2', () {
      expect(AttendanceStatus.present.value, 'PRESENT');
      expect(AttendanceStatus.absent.value, 'ABSENT');
      expect(AttendanceStatus.unmarked.value, 'UNMARKED');
      expect(AttendanceStatus.cancelled.value, 'CANCELLED');

      expect(AttendanceStatus.fromString('PRESENT'), AttendanceStatus.present);
      expect(AttendanceStatus.fromString('present '), AttendanceStatus.present);
      expect(AttendanceStatus.fromString('ABSENT'), AttendanceStatus.absent);
      expect(
        AttendanceStatus.fromString('CANCELLED'),
        AttendanceStatus.cancelled,
      );
      expect(AttendanceStatus.fromString('INVALID'), AttendanceStatus.unmarked);
      expect(AttendanceStatus.fromString(null), AttendanceStatus.unmarked);

      expect(AttendanceStatus.present.isConducted, isTrue);
      expect(AttendanceStatus.absent.isConducted, isTrue);
      expect(AttendanceStatus.unmarked.isConducted, isFalse);
      expect(AttendanceStatus.cancelled.isConducted, isFalse);
    });

    test('AttendanceRecordEntity default properties and copyWith', () {
      final record = AttendanceRecordEntity(
        id: 'rec-1',
        date: '2026-03-01',
        sessionId: 'session-101',
        status: AttendanceStatus.present,
        createdAt: now,
        updatedAt: now,
      );

      expect(record.id, 'rec-1');
      expect(record.date, '2026-03-01');
      expect(record.subjectId, dailySubjectId);
      expect(record.sessionId, 'session-101');
      expect(record.status, AttendanceStatus.present);
      expect(record.isDeleted, isFalse);

      final updated = record.copyWith(
        status: AttendanceStatus.absent,
        subjectId: 'sub-cs101',
      );

      expect(updated.status, AttendanceStatus.absent);
      expect(updated.subjectId, 'sub-cs101');
      expect(updated.date, '2026-03-01');
    });

    test('AttendanceRecordEntity soft-delete tombstone handling', () {
      final record = AttendanceRecordEntity(
        id: 'rec-1',
        date: '2026-03-01',
        sessionId: 'session-101',
        status: AttendanceStatus.present,
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      );

      expect(record.isDeleted, isTrue);

      final restored = record.copyWith(clearDeletedAt: true);
      expect(restored.isDeleted, isFalse);
      expect(restored.deletedAt, isNull);
    });

    test('AttendanceRecordEntity equality and hashCode', () {
      final r1 = AttendanceRecordEntity(
        id: 'rec-1',
        date: '2026-03-01',
        sessionId: 'session-101',
        status: AttendanceStatus.present,
        createdAt: now,
        updatedAt: now,
      );

      final r2 = AttendanceRecordEntity(
        id: 'rec-1',
        date: '2026-03-01',
        sessionId: 'session-101',
        status: AttendanceStatus.present,
        createdAt: now,
        updatedAt: now,
      );

      final r3 = r1.copyWith(status: AttendanceStatus.absent);

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));
    });
  });
}
