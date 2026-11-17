import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/attendance/data/models/legacy_attendance_model.dart';
import 'package:flutter_app/features/attendance/domain/entities/legacy_attendance_entity.dart';

void main() {
  group('LegacyAttendanceModel Serialization Unit Tests', () {
    final now = DateTime(2026, 3, 1, 10, 0);

    test('serializes toMap correctly', () {
      final model = LegacyAttendanceModel(
        id: 'legacy-2026-03-01',
        date: '2026-03-01',
        held: 6,
        attended: 5,
        createdAt: now,
        updatedAt: now,
      );

      final map = model.toMap();

      expect(map['id'], 'legacy-2026-03-01');
      expect(map['date'], '2026-03-01');
      expect(map['held'], 6);
      expect(map['attended'], 5);
      expect(map['createdAt'], now.toIso8601String());
      expect(map['updatedAt'], now.toIso8601String());
      expect(map['deletedAt'], isNull);
    });

    test('deserializes fromMap with valid data', () {
      final map = {
        'id': 'legacy-2026-03-02',
        'date': '2026-03-02',
        'held': 4,
        'attended': 3,
        'createdAt': '2026-03-02T10:00:00.000',
        'updatedAt': '2026-03-02T11:00:00.000',
        'deletedAt': '2026-03-02T12:00:00.000',
      };

      final model = LegacyAttendanceModel.fromMap(map);

      expect(model.id, 'legacy-2026-03-02');
      expect(model.date, '2026-03-02');
      expect(model.held, 4);
      expect(model.attended, 3);
      expect(model.isDeleted, isTrue);
    });

    test('deserializes defensively from empty map', () {
      final model = LegacyAttendanceModel.fromMap({});

      expect(model.id, '');
      expect(model.date, '');
      expect(model.held, 0);
      expect(model.attended, 0);
      expect(model.deletedAt, isNull);
    });

    test('creates model from entity via fromEntity', () {
      final entity = LegacyAttendanceEntity(
        id: 'leg-3',
        date: '2026-03-03',
        held: 2,
        attended: 2,
        createdAt: now,
        updatedAt: now,
      );

      final model = LegacyAttendanceModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.held, entity.held);
      expect(model.attended, entity.attended);
    });
  });
}
