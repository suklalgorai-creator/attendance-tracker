import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/notes/data/models/note_model.dart';
import 'package:flutter_app/features/notes/domain/entities/note_entity.dart';

void main() {
  group('NoteModel Serialization Unit Tests', () {
    final now = DateTime(2026, 3, 1, 15, 0);

    test('serializes toMap with Schema V2 structure', () {
      final reminder = DateTime(2026, 3, 10, 9, 0);
      final model = NoteModel(
        id: 'note-1',
        content: 'Midterm exams schedule',
        color: '#fef3c7',
        reminderDate: reminder,
        createdAt: now,
      );

      final map = model.toMap();

      expect(map['id'], 'note-1');
      expect(map['content'], 'Midterm exams schedule');
      expect(map['color'], '#fef3c7');
      expect(map['reminderDate'], reminder.toIso8601String());
      expect(map['createdAt'], now.toIso8601String());
    });

    test('deserializes fromMap with valid data', () {
      final map = {
        'id': 'note-2',
        'content': 'Library books return',
        'color': '#d1fae5',
        'reminderDate': '2026-03-05T18:00:00.000',
        'createdAt': '2026-03-01T12:00:00.000',
      };

      final model = NoteModel.fromMap(map);

      expect(model.id, 'note-2');
      expect(model.content, 'Library books return');
      expect(model.color, '#d1fae5');
      expect(model.reminderDate, DateTime.parse('2026-03-05T18:00:00.000'));
    });

    test('deserializes fromMap with empty data gracefully', () {
      final model = NoteModel.fromMap({});

      expect(model.id, '');
      expect(model.content, '');
      expect(model.color, 'var(--input-bg)');
      expect(model.reminderDate, isNull);
    });

    test('creates model from entity via fromEntity', () {
      final entity = NoteEntity(
        id: 'note-3',
        content: 'Project submission',
        createdAt: now,
      );

      final model = NoteModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.content, entity.content);
      expect(model.color, entity.color);
    });
  });
}
