import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources/notes_local_datasource.dart';
import '../models/note_model.dart';

/// Repository delegating sticky note CRUD and reactive streams to [NotesLocalDataSource].
///
/// Ownership: Notes Feature (Data Layer)
// ==========================================
// NOTES REPOSITORY - Implementation
// ==========================================
class NotesRepositoryImpl implements NotesRepository {
  final NotesLocalDataSource _localDataSource;

  NotesRepositoryImpl({NotesLocalDataSource? localDataSource})
    : _localDataSource = localDataSource ?? NotesLocalDataSourceImpl();

  @override
  Future<List<NoteEntity>> getNotes() async {
    return _localDataSource.getNotes();
  }

  @override
  Stream<List<NoteEntity>> watchNotes() {
    return _localDataSource.watchNotes();
  }

  @override
  Future<NoteEntity?> getNoteById(String id) async {
    return _localDataSource.getNoteById(id);
  }

  @override
  Future<void> saveNote(NoteEntity note) async {
    final model = NoteModel.fromEntity(note);
    await _localDataSource.saveNote(model);
  }

  @override
  Future<void> saveNotes(List<NoteEntity> notes) async {
    final models = notes.map(NoteModel.fromEntity).toList();
    await _localDataSource.saveNotes(models);
  }

  @override
  Future<void> deleteNote(String id) async {
    await _localDataSource.deleteNote(id);
  }

  @override
  Future<void> clearAllNotes() async {
    await _localDataSource.clearAllNotes();
  }
}
