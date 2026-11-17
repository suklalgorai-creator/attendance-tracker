import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:flutter_app/features/notes/data/models/note_model.dart';
import 'package:flutter_app/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:flutter_app/features/notes/domain/entities/note_entity.dart';

class FakeNotesLocalDataSource implements NotesLocalDataSource {
  final List<NoteModel> _notes = [];
  final _controller = StreamController<List<NoteModel>>.broadcast();

  void _notify() => _controller.add(List.unmodifiable(_notes));

  @override
  Future<List<NoteModel>> getNotes() async => List.from(_notes);

  @override
  Stream<List<NoteModel>> watchNotes() async* {
    yield List.from(_notes);
    yield* _controller.stream;
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    final match = _notes.where((n) => n.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<void> saveNote(NoteModel note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    _notify();
  }

  @override
  Future<void> saveNotes(List<NoteModel> notes) async {
    _notes.clear();
    _notes.addAll(notes);
    _notify();
  }

  @override
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    _notify();
  }

  @override
  Future<void> clearAllNotes() async {
    _notes.clear();
    _notify();
  }
}

void main() {
  group('NotesRepositoryImpl Unit Tests', () {
    late FakeNotesLocalDataSource fakeDataSource;
    late NotesRepositoryImpl repository;
    final now = DateTime(2026, 3, 1, 14, 0);

    setUp(() {
      fakeDataSource = FakeNotesLocalDataSource();
      repository = NotesRepositoryImpl(localDataSource: fakeDataSource);
    });

    test('saveNote and getNotes retrieves stored notes', () async {
      final note1 = NoteEntity(id: 'n1', content: 'Buy textbooks', createdAt: now);
      final note2 = NoteEntity(id: 'n2', content: 'Submit report', createdAt: now);

      await repository.saveNote(note1);
      await repository.saveNote(note2);

      final list = await repository.getNotes();
      expect(list.length, 2);
      expect(list.first.id, 'n1');
      expect(list.last.id, 'n2');
    });

    test('getNoteById returns correct note or null', () async {
      final note = NoteEntity(id: 'n-spec', content: 'Specific note', createdAt: now);
      await repository.saveNote(note);

      expect(await repository.getNoteById('n-spec'), isNotNull);
      expect(await repository.getNoteById('missing'), isNull);
    });

    test('saveNotes batch saves notes', () async {
      final notes = [
        NoteEntity(id: 'b1', content: 'Note 1', createdAt: now),
        NoteEntity(id: 'b2', content: 'Note 2', createdAt: now),
      ];

      await repository.saveNotes(notes);
      expect((await repository.getNotes()).length, 2);
    });

    test('deleteNote permanently removes note', () async {
      final note = NoteEntity(id: 'n-del', content: 'To delete', createdAt: now);
      await repository.saveNote(note);

      expect((await repository.getNotes()).length, 1);

      await repository.deleteNote('n-del');
      expect((await repository.getNotes()).isEmpty, isTrue);
    });

    test('clearAllNotes removes all notes', () async {
      await repository.saveNote(NoteEntity(id: 'n1', content: 'Note 1', createdAt: now));
      await repository.saveNote(NoteEntity(id: 'n2', content: 'Note 2', createdAt: now));

      expect((await repository.getNotes()).length, 2);

      await repository.clearAllNotes();
      expect((await repository.getNotes()).isEmpty, isTrue);
    });

    test('watchNotes emits reactive updates', () async {
      final note = NoteEntity(id: 'n-watch', content: 'Stream note', createdAt: now);

      expectLater(
        repository.watchNotes(),
        emitsInOrder([
          [],
          [note],
        ]),
      );

      await pumpEventQueue();
      await repository.saveNote(note);
    });
  });
}
