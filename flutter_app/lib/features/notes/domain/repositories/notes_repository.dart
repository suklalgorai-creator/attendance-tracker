import '../entities/note_entity.dart';

/// Abstract contract for Sticky Notes operations in Domain layer.
abstract class NotesRepository {
  Future<List<NoteEntity>> getNotes();
  Stream<List<NoteEntity>> watchNotes();
  Future<NoteEntity?> getNoteById(String id);
  Future<void> saveNote(NoteEntity note);
  Future<void> saveNotes(List<NoteEntity> notes);
  Future<void> deleteNote(String id);
  Future<void> clearAllNotes();
}
