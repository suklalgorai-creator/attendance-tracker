import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/timetable/data/models/timetable_model.dart';
import 'package:flutter_app/features/timetable/domain/entities/timetable_session_entity.dart';

void main() {
  group('TimetableModel Serialization Unit Tests', () {
    final now = DateTime(2026, 3, 1, 10, 0);

    test('serializes toMap with correct Schema V2 field names', () {
      final model = TimetableModel(
        id: 'schedule-101',
        subjectId: 'sub-math',
        label: 'Mathematics',
        dayOfWeek: 1,
        active: true,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
      );

      final map = model.toMap();

      expect(map['id'], 'schedule-101');
      expect(map['subjectId'], 'sub-math');
      expect(map['label'], 'Mathematics');
      expect(map['dayOfWeek'], 1);
      expect(map['active'], isTrue);
      expect(map['createdAt'], now.toIso8601String());
      expect(map['updatedAt'], now.toIso8601String());
      expect(map['deletedAt'], isNull);
    });

    test('deserializes fromMap with valid Map data', () {
      final map = {
        'id': 'schedule-102',
        'subjectId': 'sub-phy',
        'label': 'Physics Lab',
        'dayOfWeek': 2,
        'active': false,
        'createdAt': '2026-03-01T10:00:00.000',
        'updatedAt': '2026-03-01T12:00:00.000',
        'deletedAt': '2026-03-01T14:00:00.000',
      };

      final model = TimetableModel.fromMap(map);

      expect(model.id, 'schedule-102');
      expect(model.subjectId, 'sub-phy');
      expect(model.label, 'Physics Lab');
      expect(model.dayOfWeek, 2);
      expect(model.active, isFalse);
      expect(model.isDeleted, isTrue);
      expect(model.deletedAt, DateTime(2026, 3, 1, 14, 0));
    });

    test('fromEntity maps all properties accurately', () {
      final entity = TimetableSessionEntity(
        id: 'schedule-ent',
        subjectId: 'sub-chem',
        label: 'Chemistry',
        dayOfWeek: 3,
        active: true,
        createdAt: now,
        updatedAt: now,
      );

      final model = TimetableModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.subjectId, entity.subjectId);
      expect(model.label, entity.label);
      expect(model.dayOfWeek, entity.dayOfWeek);
      expect(model.active, entity.active);
      expect(model.createdAt, entity.createdAt);
      expect(model.updatedAt, entity.updatedAt);
      expect(model.deletedAt, entity.deletedAt);
    });

    test('timetableFromMap parses string and integer day keys', () {
      final raw = {
        '1': [
          {
            'id': 's1',
            'subjectId': 'sub-1',
            'label': 'Math',
            'dayOfWeek': 1,
            'active': true,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }
        ],
        3: [
          {
            'id': 's2',
            'subjectId': 'sub-2',
            'label': 'English',
            'dayOfWeek': 3,
            'active': true,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }
        ],
        'invalid_key': [
          {'id': 's3'}
        ],
        '7': [
          {'id': 's4'} // Out of bounds day 7
        ],
      };

      final parsed = TimetableModel.timetableFromMap(raw);

      expect(parsed.containsKey(1), isTrue);
      expect(parsed[1]!.length, 1);
      expect(parsed[1]!.first.label, 'Math');

      expect(parsed.containsKey(3), isTrue);
      expect(parsed[3]!.length, 1);
      expect(parsed[3]!.first.label, 'English');

      expect(parsed.containsKey(7), isFalse);
      expect(parsed.containsKey(-1), isFalse);
    });

    test('timetableFromMap safely handles null or empty input', () {
      expect(TimetableModel.timetableFromMap(null), isEmpty);
      expect(TimetableModel.timetableFromMap({}), isEmpty);
    });

    test('timetableToMap exports Map with string keys for Schema V2', () {
      final timetable = {
        1: [
          TimetableSessionEntity(
            id: 's1',
            subjectId: 'sub-1',
            label: 'Math',
            dayOfWeek: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        5: [
          TimetableSessionEntity(
            id: 's2',
            subjectId: 'sub-2',
            label: 'Physics',
            dayOfWeek: 5,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      };

      final serialized = TimetableModel.timetableToMap(timetable);

      expect(serialized.containsKey('1'), isTrue);
      expect(serialized.containsKey('5'), isTrue);
      expect(serialized['1'], isA<List>());
      expect((serialized['1'] as List).first['label'], 'Math');
      expect((serialized['5'] as List).first['label'], 'Physics');
    });

    test('typedef TimetableSessionModel matches TimetableModel', () {
      expect(TimetableSessionModel, equals(TimetableModel));
    });
  });
}
