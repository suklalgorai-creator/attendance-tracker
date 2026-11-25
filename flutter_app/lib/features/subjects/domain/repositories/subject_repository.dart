import '../entities/subject_entity.dart';

/// Abstract contract for Subject data operations in Domain layer.
abstract class SubjectRepository {
  Future<List<SubjectEntity>> getSubjects({bool includeDeleted = false});
  Stream<List<SubjectEntity>> watchSubjects({bool includeDeleted = false});
  Future<SubjectEntity?> getSubjectById(String id);
  Future<void> saveSubject(SubjectEntity subject);
  Future<void> saveSubjects(List<SubjectEntity> subjects);
  Future<void> reorderSubjects(List<String> orderedIds);
  Future<void> deleteSubject(
    String id,
  ); // Soft delete: sets deletedAt = now, updates updatedAt
  Future<void> restoreSubject(
    String id,
  ); // Resets deletedAt = null, updates updatedAt
  Future<void> hardDeleteSubject(String id); // Permanently removes from storage
}
