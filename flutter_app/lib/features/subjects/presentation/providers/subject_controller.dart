import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/subject_entity.dart';
import '../../domain/repositories/subject_repository.dart';

/// StateNotifier for Subject CRUD and reordering operations.
class SubjectController extends StateNotifier<AsyncValue<void>> {
  final SubjectRepository _repository;
  String? _lastDeletedSubjectId;

  SubjectController(this._repository) : super(const AsyncValue.data(null));

  /// ID of the most recently deleted subject (for undo purposes).
  String? get lastDeletedSubjectId => _lastDeletedSubjectId;

  /// Adds a new subject with validation.
  Future<void> addSubject({
    required String name,
    String? code,
    String color = '#10B981',
    String icon = 'school',
    double? targetPercentage,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Subject name is required');
    }
    if (targetPercentage != null && (targetPercentage <= 0 || targetPercentage > 100)) {
      throw ArgumentError('Target must be between 0 and 100%');
    }

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final existing = await _repository.getSubjects(includeDeleted: true);
      final sortOrder = existing.length;

      final newSubject = SubjectEntity(
        id: 'sub_${now.millisecondsSinceEpoch}',
        name: trimmedName.length > 120 ? trimmedName.substring(0, 120) : trimmedName,
        code: (code != null && code.trim().isNotEmpty)
            ? (code.trim().length > 20 ? code.trim().substring(0, 20) : code.trim())
            : null,
        color: color,
        icon: icon,
        targetPercentage: targetPercentage,
        sortOrder: sortOrder,
        active: true,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.saveSubject(newSubject);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Updates an existing subject with validation.
  Future<void> updateSubject(SubjectEntity subject) async {
    final trimmedName = subject.name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Subject name is required');
    }
    if (subject.targetPercentage != null &&
        (subject.targetPercentage! <= 0 || subject.targetPercentage! > 100)) {
      throw ArgumentError('Target must be between 0 and 100%');
    }

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final updated = subject.copyWith(
        name: trimmedName.length > 120 ? trimmedName.substring(0, 120) : trimmedName,
        code: subject.code?.trim().isEmpty == true ? null : subject.code?.trim(),
        updatedAt: now,
      );

      await _repository.saveSubject(updated);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Performs soft-deletion of a subject by ID.
  Future<void> deleteSubject(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteSubject(id);
      _lastDeletedSubjectId = id;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Restores a soft-deleted subject by ID.
  Future<void> restoreSubject(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.restoreSubject(id);
      if (_lastDeletedSubjectId == id) {
        _lastDeletedSubjectId = null;
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Updates subject sort orders according to the ordered ID list.
  Future<void> reorderSubjects(List<String> orderedIds) async {
    state = const AsyncValue.loading();
    try {
      await _repository.reorderSubjects(orderedIds);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
