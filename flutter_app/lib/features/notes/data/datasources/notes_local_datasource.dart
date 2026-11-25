import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/database_service.dart';
import '../models/note_model.dart';

/// Hive local persistence contract and implementation for sticky notes.
///
/// Ownership: Notes Feature (Data Layer)
// ==========================================
// NOTES DATA SOURCE - Hive Sticky Notes Storage
// ==========================================
abstract class NotesLocalDataSource {
  Future<List<NoteModel>> getNotes();
  Stream<List<NoteModel>> watchNotes();
  Future<NoteModel?> getNoteById(String id);
  Future<void> saveNote(NoteModel note);
  Future<void> saveNotes(List<NoteModel> notes);
  Future<void> deleteNote(String id);
  Future<void> clearAllNotes();
}

class NotesLocalDataSourceImpl implements NotesLocalDataSource {
  final Box _box;

  NotesLocalDataSourceImpl({Box? box})
    : _box = box ?? DatabaseService.getBox(DatabaseService.notesBoxName);

  @override
  Future<List<NoteModel>> getNotes() async {
    try {
      final rawData = _box.get('items', defaultValue: []);
      if (rawData is List) {
        return rawData
            .whereType<Map>()
            .map((item) => NoteModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } catch (e) {
      throw CacheException('Failed to load notes: $e');
    }
  }

  @override
  Stream<List<NoteModel>> watchNotes() async* {
    yield await getNotes();
    yield* _box.watch(key: 'items').asyncMap((_) => getNotes());
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    try {
      final current = await getNotes();
      final match = current.where((n) => n.id == id);
      return match.isNotEmpty ? match.first : null;
    } catch (e) {
      throw CacheException('Failed to get note by id: $e');
    }
  }

  @override
  Future<void> saveNotes(List<NoteModel> notes) async {
    try {
      final list = notes.map((n) => n.toMap()).toList();
      await _box.put('items', list);
    } catch (e) {
      throw CacheException('Failed to save notes: $e');
    }
  }

  @override
  Future<void> saveNote(NoteModel note) async {
    try {
      final current = await getNotes();
      final index = current.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        current[index] = note;
      } else {
        current.add(note);
      }
      await saveNotes(current);
    } catch (e) {
      throw CacheException('Failed to save note: $e');
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    try {
      final current = await getNotes();
      current.removeWhere((n) => n.id == id);
      await saveNotes(current);
    } catch (e) {
      throw CacheException('Failed to delete note: $e');
    }
  }

  @override
  Future<void> clearAllNotes() async {
    try {
      await _box.put('items', []);
    } catch (e) {
      throw CacheException('Failed to clear notes: $e');
    }
  }
}
