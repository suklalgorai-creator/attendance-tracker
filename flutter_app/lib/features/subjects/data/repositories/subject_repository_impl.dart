import '../../domain/entities/subject_entity.dart';
import '../../domain/repositories/subject_repository.dart';
import '../datasources/subject_local_datasource.dart';
import '../models/subject_model.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  final SubjectLocalDataSource _localDataSource;

  SubjectRepositoryImpl({SubjectLocalDataSource? localDataSource})
    : _localDataSource = localDataSource ?? SubjectLocalDataSourceImpl();

  int _compareSubjects(SubjectEntity a, SubjectEntity b) {
    final orderComparison = a.sortOrder.compareTo(b.sortOrder);
    if (orderComparison != 0) return orderComparison;
    return a.createdAt.compareTo(b.createdAt);
  }

  @override
  Future<List<SubjectEntity>> getSubjects({bool includeDeleted = false}) async {
    final models = await _localDataSource.getSubjects();
    final sorted = models.toList()..sort(_compareSubjects);
    if (includeDeleted) {
      return sorted;
    }
    return sorted.where((s) => !s.isDeleted).toList();
  }

  @override
  Stream<List<SubjectEntity>> watchSubjects({bool includeDeleted = false}) {
    return _localDataSource.watchSubjects().map((list) {
      final sorted = list.toList()..sort(_compareSubjects);
      if (includeDeleted) {
        return sorted;
      }
      return sorted.where((s) => !s.isDeleted).toList();
    });
  }

  @override
  Future<void> saveSubject(SubjectEntity subject) async {
    final model = SubjectModel.fromEntity(subject);
    await _localDataSource.saveSubject(model);
  }

  @override
  Future<void> saveSubjects(List<SubjectEntity> subjects) async {
    final models = subjects.map(SubjectModel.fromEntity).toList();
    await _localDataSource.saveSubjects(models);
  }

  @override
  Future<void> reorderSubjects(List<String> orderedIds) async {
    final models = await _localDataSource.getSubjects();
    final now = DateTime.now();
    final updated = models.map((model) {
      final index = orderedIds.indexOf(model.id);
      if (index >= 0) {
        return SubjectModel.fromEntity(
          model.copyWith(sortOrder: index, updatedAt: now),
        );
      }
      return model;
    }).toList();
    await _localDataSource.saveSubjects(updated);
  }

  @override
  Future<void> deleteSubject(String id) async {
    // Soft deletion matching React dataModel.js
    final subject = await _localDataSource.getSubjectById(id);
    if (subject != null) {
      final now = DateTime.now();
      final updated = subject.copyWith(deletedAt: now, updatedAt: now);
      await _localDataSource.saveSubject(SubjectModel.fromEntity(updated));
    }
  }

  @override
  Future<void> restoreSubject(String id) async {
    final subject = await _localDataSource.getSubjectById(id);
    if (subject != null && subject.isDeleted) {
      final updated = subject.copyWith(
        clearDeletedAt: true,
        updatedAt: DateTime.now(),
      );
      await _localDataSource.saveSubject(SubjectModel.fromEntity(updated));
    }
  }

  @override
  Future<void> hardDeleteSubject(String id) async {
    await _localDataSource.deleteSubject(id);
  }

  @override
  Future<SubjectEntity?> getSubjectById(String id) async {
    final model = await _localDataSource.getSubjectById(id);
    if (model != null && !model.isDeleted) {
      return model;
    }
    return null;
  }
}
