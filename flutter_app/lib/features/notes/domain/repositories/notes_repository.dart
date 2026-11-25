import '../entities/note_entity.dart';

/// Domain repository contract for sticky note storage and reactive streaming.
///
/// Ownership: Notes Feature (Domain Contract)
// ==========================================
// NOTES REPOSITORY - Domain Interface
// ==========================================
abstract class NotesRepository {
  Future<List<NoteEntity>> getNotes();
  Stream<List<NoteEntity>> watchNotes();
  Future<NoteEntity?> getNoteById(String id);
  Future<void> saveNote(NoteEntity note);
  Future<void> saveNotes(List<NoteEntity> notes);
  Future<void> deleteNote(String id);
  Future<void> clearAllNotes();
}
