import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/subjects/data/models/subject_model.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';

void main() {
  group('SubjectModel Serialization Unit Tests', () {
    final now = DateTime(2026, 3, 1, 10, 0);

    test('serializes toMap with Schema V2 keys', () {
      final model = SubjectModel(
        id: 'sub-1',
        name: 'Mathematics',
        color: '#10B981',
        active: true,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
      );

      final map = model.toMap();

      expect(map['id'], 'sub-1');
      expect(map['name'], 'Mathematics');
      expect(map['color'], '#10B981');
      expect(map['active'], isTrue);
      expect(map['createdAt'], now.toIso8601String());
      expect(map['updatedAt'], now.toIso8601String());
      expect(map['deletedAt'], isNull);
    });

    test('deserializes fromMap with valid Schema V2 data', () {
      final map = {
        'id': 'sub-2',
        'name': 'Physics',
        'color': '#3B82F6',
        'active': false,
        'createdAt': '2026-03-01T10:00:00.000',
        'updatedAt': '2026-03-01T12:00:00.000',
        'deletedAt': '2026-03-01T14:00:00.000',
      };

      final model = SubjectModel.fromMap(map);

      expect(model.id, 'sub-2');
      expect(model.name, 'Physics');
      expect(model.color, '#3B82F6');
      expect(model.active, isFalse);
      expect(model.createdAt, DateTime.parse('2026-03-01T10:00:00.000'));
      expect(model.updatedAt, DateTime.parse('2026-03-01T12:00:00.000'));
      expect(model.deletedAt, DateTime.parse('2026-03-01T14:00:00.000'));
      expect(model.isDeleted, isTrue);
    });

    test('deserializes fromMap gracefully with missing or null fields', () {
      final emptyMap = <String, dynamic>{};
      final model = SubjectModel.fromMap(emptyMap);

      expect(model.id, '');
      expect(model.name, '');
      expect(model.color, '#10B981');
      expect(model.active, isTrue);
      expect(model.deletedAt, isNull);
      expect(model.createdAt, isA<DateTime>());
      expect(model.updatedAt, isA<DateTime>());
    });

    test('creates model from entity via fromEntity', () {
      final entity = SubjectEntity(
        id: 'sub-3',
        name: 'Chemistry',
        color: '#F59E0B',
        active: true,
        createdAt: now,
        updatedAt: now,
      );

      final model = SubjectModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.name, entity.name);
      expect(model.color, entity.color);
      expect(model.active, entity.active);
      expect(model.createdAt, entity.createdAt);
      expect(model.updatedAt, entity.updatedAt);
    });
  });
}
