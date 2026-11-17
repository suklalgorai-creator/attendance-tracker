import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';

void main() {
  group('SubjectEntity Unit Tests', () {
    final now = DateTime(2026, 3, 1, 10, 0);

    test('instantiates with correct properties and default values', () {
      final subject = SubjectEntity(
        id: 'sub-1',
        name: 'Mathematics',
        createdAt: now,
        updatedAt: now,
      );

      expect(subject.id, 'sub-1');
      expect(subject.name, 'Mathematics');
      expect(subject.color, '#10B981');
      expect(subject.active, isTrue);
      expect(subject.isDeleted, isFalse);
      expect(subject.deletedAt, isNull);
    });

    test('isDeleted returns true when deletedAt is set', () {
      final subject = SubjectEntity(
        id: 'sub-1',
        name: 'Mathematics',
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      );

      expect(subject.isDeleted, isTrue);
      expect(subject.deletedAt, now);
    });

    test('copyWith creates a new instance with modified values', () {
      final subject = SubjectEntity(
        id: 'sub-1',
        name: 'Mathematics',
        createdAt: now,
        updatedAt: now,
      );

      final updated = subject.copyWith(
        name: 'Advanced Mathematics',
        color: '#3B82F6',
        active: false,
      );

      expect(updated.id, 'sub-1');
      expect(updated.name, 'Advanced Mathematics');
      expect(updated.color, '#3B82F6');
      expect(updated.active, isFalse);
      expect(updated.createdAt, now);
    });

    test('copyWith clearDeletedAt clears deletedAt tombstone', () {
      final subject = SubjectEntity(
        id: 'sub-1',
        name: 'Mathematics',
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      );

      expect(subject.isDeleted, isTrue);

      final restored = subject.copyWith(clearDeletedAt: true);
      expect(restored.isDeleted, isFalse);
      expect(restored.deletedAt, isNull);
    });

    test('equality and hashCode verify value equivalence', () {
      final subjectA = SubjectEntity(
        id: 'sub-1',
        name: 'Physics',
        color: '#6366F1',
        createdAt: now,
        updatedAt: now,
      );

      final subjectB = SubjectEntity(
        id: 'sub-1',
        name: 'Physics',
        color: '#6366F1',
        createdAt: now,
        updatedAt: now,
      );

      final subjectC = SubjectEntity(
        id: 'sub-2',
        name: 'Chemistry',
        createdAt: now,
        updatedAt: now,
      );

      expect(subjectA, equals(subjectB));
      expect(subjectA.hashCode, equals(subjectB.hashCode));
      expect(subjectA, isNot(equals(subjectC)));
    });
  });
}
