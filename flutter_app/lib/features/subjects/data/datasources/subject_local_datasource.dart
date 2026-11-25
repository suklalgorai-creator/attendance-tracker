import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/database_service.dart';
import '../models/subject_model.dart';

abstract class SubjectLocalDataSource {
  Future<List<SubjectModel>> getSubjects();
  Stream<List<SubjectModel>> watchSubjects();
  Future<void> saveSubject(SubjectModel subject);
  Future<void> saveSubjects(List<SubjectModel> subjects);
  Future<void> deleteSubject(String id);
  Future<SubjectModel?> getSubjectById(String id);
  Future<void> clear();
}

class SubjectLocalDataSourceImpl implements SubjectLocalDataSource {
  final Box _box;

  SubjectLocalDataSourceImpl({Box? box})
    : _box = box ?? DatabaseService.getBox(DatabaseService.subjectsV2BoxName);

  @override
  Future<List<SubjectModel>> getSubjects() async {
    try {
      final rawData = _box.get('items', defaultValue: []);
      if (rawData is List) {
        return rawData
            .map(
              (item) =>
                  SubjectModel.fromMap(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      throw CacheException('Failed to load subjects: $e');
    }
  }

  @override
  Stream<List<SubjectModel>> watchSubjects() async* {
    yield await getSubjects();
    yield* _box.watch(key: 'items').asyncMap((_) => getSubjects());
  }

  @override
  Future<void> saveSubjects(List<SubjectModel> subjects) async {
    try {
      final list = subjects.map((s) => s.toMap()).toList();
      await _box.put('items', list);
    } catch (e) {
      throw CacheException('Failed to save subjects: $e');
    }
  }

  @override
  Future<void> saveSubject(SubjectModel subject) async {
    try {
      final current = await getSubjects();
      final index = current.indexWhere((s) => s.id == subject.id);
      if (index >= 0) {
        current[index] = subject;
      } else {
        current.add(subject);
      }
      await saveSubjects(current);
    } catch (e) {
      throw CacheException('Failed to save subject: $e');
    }
  }

  @override
  Future<void> deleteSubject(String id) async {
    try {
      final current = await getSubjects();
      current.removeWhere((s) => s.id == id);
      await saveSubjects(current);
    } catch (e) {
      throw CacheException('Failed to delete subject: $e');
    }
  }

  @override
  Future<SubjectModel?> getSubjectById(String id) async {
    try {
      final current = await getSubjects();
      final match = current.where((s) => s.id == id);
      return match.isNotEmpty ? match.first : null;
    } catch (e) {
      throw CacheException('Failed to fetch subject by id: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _box.put('items', []);
    } catch (e) {
      throw CacheException('Failed to clear subjects: $e');
    }
  }
}
