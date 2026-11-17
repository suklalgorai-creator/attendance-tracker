import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/notes/domain/entities/note_entity.dart';

void main() {
  group('NoteEntity Unit Tests', () {
    final now = DateTime(2026, 3, 1, 14, 0);

    test('instantiates with defaults and properties', () {
      final note = NoteEntity(
        id: 'note-1',
        content: 'Review chapter 4 for exam',
        createdAt: now,
      );

      expect(note.id, 'note-1');
      expect(note.content, 'Review chapter 4 for exam');
      expect(note.color, 'var(--input-bg)');
      expect(note.reminderDate, isNull);
      expect(note.createdAt, now);
    });

    test('copyWith updates fields and handles clearReminder', () {
      final reminder = DateTime(2026, 3, 5, 18, 0);
      final note = NoteEntity(
        id: 'note-1',
        content: 'Submit assignment',
        color: '#fef3c7',
        reminderDate: reminder,
        createdAt: now,
      );

      expect(note.reminderDate, reminder);

      final cleared = note.copyWith(clearReminder: true);
      expect(cleared.reminderDate, isNull);
      expect(cleared.content, 'Submit assignment');
      expect(cleared.color, '#fef3c7');
    });

    test('equality and hashCode verify value equivalence', () {
      final n1 = NoteEntity(
        id: 'note-1',
        content: 'Test content',
        createdAt: now,
      );

      final n2 = NoteEntity(
        id: 'note-1',
        content: 'Test content',
        createdAt: now,
      );

      final n3 = NoteEntity(
        id: 'note-2',
        content: 'Different content',
        createdAt: now,
      );

      expect(n1, equals(n2));
      expect(n1.hashCode, equals(n2.hashCode));
      expect(n1, isNot(equals(n3)));
    });
  });
}
