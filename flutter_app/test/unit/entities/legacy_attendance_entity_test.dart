import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';

void main() {
  group('LegacyAttendanceEntity Unit Tests', () {
    final now = DateTime(2026, 3, 1, 12, 0);

    test('instantiates with held and attended totals', () {
      final legacy = LegacyAttendanceEntity(
        id: 'legacy-2026-03-01',
        date: '2026-03-01',
        held: 5,
        attended: 4,
        createdAt: now,
        updatedAt: now,
      );

      expect(legacy.id, 'legacy-2026-03-01');
      expect(legacy.date, '2026-03-01');
      expect(legacy.held, 5);
      expect(legacy.attended, 4);
      expect(legacy.isDeleted, isFalse);
    });

    test('copyWith updates fields and handles clearDeletedAt', () {
      final legacy = LegacyAttendanceEntity(
        id: 'legacy-2026-03-01',
        date: '2026-03-01',
        held: 5,
        attended: 4,
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      );

      expect(legacy.isDeleted, isTrue);

      final restored = legacy.copyWith(
        held: 6,
        attended: 5,
        clearDeletedAt: true,
      );

      expect(restored.held, 6);
      expect(restored.attended, 5);
      expect(restored.isDeleted, isFalse);
      expect(restored.deletedAt, isNull);
    });

    test('equality and hashCode verify value equivalence', () {
      final a = LegacyAttendanceEntity(
        id: 'leg-1',
        date: '2026-03-01',
        held: 4,
        attended: 3,
        createdAt: now,
        updatedAt: now,
      );

      final b = LegacyAttendanceEntity(
        id: 'leg-1',
        date: '2026-03-01',
        held: 4,
        attended: 3,
        createdAt: now,
        updatedAt: now,
      );

      final c = a.copyWith(attended: 4);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
