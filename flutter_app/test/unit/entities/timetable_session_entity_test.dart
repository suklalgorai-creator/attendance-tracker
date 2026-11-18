import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/timetable/domain/entities/timetable_session_entity.dart';

void main() {
  group('TimetableSessionEntity Unit Tests', () {
    final now = DateTime(2026, 3, 1, 10, 0);

    test('instantiates with correct properties and default values', () {
      final session = TimetableSessionEntity(
        id: 'schedule-1',
        subjectId: 'sub-math',
        label: 'Mathematics',
        dayOfWeek: 1, // Monday
        createdAt: now,
        updatedAt: now,
      );

      expect(session.id, 'schedule-1');
      expect(session.subjectId, 'sub-math');
      expect(session.label, 'Mathematics');
      expect(session.dayOfWeek, 1);
      expect(session.active, isTrue);
      expect(session.isDeleted, isFalse);
      expect(session.deletedAt, isNull);
      expect(session.createdAt, now);
      expect(session.updatedAt, now);
    });

    test('isDeleted returns true when deletedAt is set', () {
      final session = TimetableSessionEntity(
        id: 'schedule-2',
        subjectId: 'sub-phy',
        label: 'Physics',
        dayOfWeek: 2,
        active: true,
        createdAt: now,
        updatedAt: now,
        deletedAt: now.add(const Duration(hours: 1)),
      );

      expect(session.isDeleted, isTrue);
    });

    test('isDeleted returns true when active is false', () {
      final session = TimetableSessionEntity(
        id: 'schedule-3',
        subjectId: 'sub-chem',
        label: 'Chemistry',
        dayOfWeek: 3,
        active: false,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
      );

      expect(session.isDeleted, isTrue);
    });

    test('copyWith updates specified fields and preserves unmodified fields', () {
      final session = TimetableSessionEntity(
        id: 'schedule-4',
        subjectId: 'sub-bio',
        label: 'Biology',
        dayOfWeek: 4,
        active: true,
        createdAt: now,
        updatedAt: now,
      );

      final updated = session.copyWith(
        label: 'Advanced Biology',
        dayOfWeek: 5,
        active: false,
      );

      expect(updated.id, 'schedule-4');
      expect(updated.subjectId, 'sub-bio');
      expect(updated.label, 'Advanced Biology');
      expect(updated.dayOfWeek, 5);
      expect(updated.active, isFalse);
      expect(updated.createdAt, now);
      expect(updated.updatedAt, now);
    });

    test('copyWith with clearDeletedAt clears deletedAt', () {
      final deletedSession = TimetableSessionEntity(
        id: 'schedule-5',
        subjectId: 'sub-eng',
        label: 'English',
        dayOfWeek: 5,
        active: true,
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      );

      expect(deletedSession.isDeleted, isTrue);

      final restored = deletedSession.copyWith(clearDeletedAt: true);
      expect(restored.deletedAt, isNull);
      expect(restored.isDeleted, isFalse);
    });

    test('value equality and hashCode behavior', () {
      final sessionA = TimetableSessionEntity(
        id: 'schedule-equal',
        subjectId: 'sub-1',
        label: 'History',
        dayOfWeek: 1,
        createdAt: now,
        updatedAt: now,
      );

      final sessionB = TimetableSessionEntity(
        id: 'schedule-equal',
        subjectId: 'sub-1',
        label: 'History',
        dayOfWeek: 1,
        createdAt: now,
        updatedAt: now,
      );

      final sessionDiff = TimetableSessionEntity(
        id: 'schedule-diff',
        subjectId: 'sub-1',
        label: 'History',
        dayOfWeek: 1,
        createdAt: now,
        updatedAt: now,
      );

      expect(sessionA, equals(sessionB));
      expect(sessionA.hashCode, equals(sessionB.hashCode));
      expect(sessionA, isNot(equals(sessionDiff)));
    });

    test('toString contains key identifying information', () {
      final session = TimetableSessionEntity(
        id: 'schedule-str',
        subjectId: 'sub-geo',
        label: 'Geography',
        dayOfWeek: 3,
        createdAt: now,
        updatedAt: now,
      );

      expect(session.toString(), contains('schedule-str'));
      expect(session.toString(), contains('sub-geo'));
      expect(session.toString(), contains('Geography'));
      expect(session.toString(), contains('dayOfWeek: 3'));
    });
  });
}
