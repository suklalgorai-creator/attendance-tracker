import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';
import 'package:flutter_app/features/subjects/domain/repositories/subject_repository.dart';
import 'package:flutter_app/features/subjects/presentation/providers/subject_controller.dart';

class FakeSubjectRepository implements SubjectRepository {
  final List<SubjectEntity> _subjects = [];
  final _controller = StreamController<List<SubjectEntity>>.broadcast();

  void _notify() {
    _controller.add(List.unmodifiable(_subjects));
  }

  @override
  Future<List<SubjectEntity>> getSubjects({bool includeDeleted = false}) async {
    if (includeDeleted) return List.from(_subjects);
    return _subjects.where((s) => !s.isDeleted).toList();
  }

  @override
  Stream<List<SubjectEntity>> watchSubjects({
    bool includeDeleted = false,
  }) async* {
    if (includeDeleted) {
      yield List.from(_subjects);
    } else {
      yield _subjects.where((s) => !s.isDeleted).toList();
    }
    yield* _controller.stream.map((list) {
      if (includeDeleted) return list;
      return list.where((s) => !s.isDeleted).toList();
    });
  }

  @override
  Future<SubjectEntity?> getSubjectById(String id) async {
    final match = _subjects.where((s) => s.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<void> saveSubject(SubjectEntity subject) async {
    final index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index >= 0) {
      _subjects[index] = subject;
    } else {
      _subjects.add(subject);
    }
    _notify();
  }

  @override
  Future<void> saveSubjects(List<SubjectEntity> subjects) async {
    _subjects.clear();
    _subjects.addAll(subjects);
    _notify();
  }

  @override
  Future<void> deleteSubject(String id) async {
    final index = _subjects.indexWhere((s) => s.id == id);
    if (index >= 0) {
      _subjects[index] = _subjects[index].copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> restoreSubject(String id) async {
    final index = _subjects.indexWhere((s) => s.id == id);
    if (index >= 0) {
      _subjects[index] = _subjects[index].copyWith(
        clearDeletedAt: true,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> hardDeleteSubject(String id) async {
    _subjects.removeWhere((s) => s.id == id);
    _notify();
  }

  @override
  Future<void> reorderSubjects(List<String> orderedIds) async {
    final now = DateTime.now();
    for (int i = 0; i < orderedIds.length; i++) {
      final id = orderedIds[i];
      final idx = _subjects.indexWhere((s) => s.id == id);
      if (idx >= 0) {
        _subjects[idx] = _subjects[idx].copyWith(sortOrder: i, updatedAt: now);
      }
    }
    _notify();
  }
}

void main() {
  group('SubjectController Unit Tests', () {
    late FakeSubjectRepository fakeRepo;
    late SubjectController controller;

    setUp(() {
      fakeRepo = FakeSubjectRepository();
      controller = SubjectController(fakeRepo);
    });

    test(
      'addSubject creates new subject with generated ID, color, icon, and target percentage',
      () async {
        await controller.addSubject(
          name: 'Database Systems',
          code: 'CS202',
          color: '#3B82F6',
          icon: 'computer',
          targetPercentage: 80.0,
        );

        final subjects = await fakeRepo.getSubjects();
        expect(subjects.length, 1);
        final created = subjects.first;
        expect(created.name, 'Database Systems');
        expect(created.code, 'CS202');
        expect(created.color, '#3B82F6');
        expect(created.icon, 'computer');
        expect(created.targetPercentage, 80.0);
        expect(created.sortOrder, 0);
        expect(created.active, isTrue);
        expect(created.isDeleted, isFalse);
      },
    );

    test(
      'addSubject rejects empty or whitespace-only subject name with error message',
      () async {
        expect(
          () => controller.addSubject(name: '   '),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'Subject name is required',
            ),
          ),
        );

        final subjects = await fakeRepo.getSubjects();
        expect(subjects.isEmpty, isTrue);
      },
    );

    test(
      'addSubject rejects invalid target percentage (< 0 or > 100)',
      () async {
        expect(
          () => controller.addSubject(name: 'Math', targetPercentage: -5.0),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'Target must be between 0 and 100%',
            ),
          ),
        );

        expect(
          () => controller.addSubject(name: 'Math', targetPercentage: 105.0),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'Target must be between 0 and 100%',
            ),
          ),
        );
      },
    );

    test(
      'updateSubject preserves ID and createdAt while updating fields',
      () async {
        final now = DateTime(2026, 3, 1, 10, 0);
        final initial = SubjectEntity(
          id: 'sub_100',
          name: 'Physics I',
          code: 'PHY101',
          color: '#10B981',
          icon: 'science',
          createdAt: now,
          updatedAt: now,
        );
        await fakeRepo.saveSubject(initial);

        final updated = initial.copyWith(
          name: 'Physics II (Advanced)',
          code: 'PHY201',
          color: '#8B5CF6',
          targetPercentage: 85.0,
        );

        await controller.updateSubject(updated);

        final subjects = await fakeRepo.getSubjects();
        expect(subjects.length, 1);
        expect(subjects.first.id, 'sub_100');
        expect(subjects.first.name, 'Physics II (Advanced)');
        expect(subjects.first.code, 'PHY201');
        expect(subjects.first.color, '#8B5CF6');
        expect(subjects.first.targetPercentage, 85.0);
        expect(subjects.first.createdAt, now);
      },
    );

    test(
      'deleteSubject performs soft deletion and tracks lastDeletedSubjectId',
      () async {
        final now = DateTime(2026, 3, 1, 10, 0);
        final subject = SubjectEntity(
          id: 'sub_to_delete',
          name: 'Biology',
          createdAt: now,
          updatedAt: now,
        );
        await fakeRepo.saveSubject(subject);

        await controller.deleteSubject('sub_to_delete');

        expect(controller.lastDeletedSubjectId, 'sub_to_delete');
        final active = await fakeRepo.getSubjects();
        expect(active.isEmpty, isTrue);

        final all = await fakeRepo.getSubjects(includeDeleted: true);
        expect(all.length, 1);
        expect(all.first.isDeleted, isTrue);
      },
    );

    test(
      'restoreSubject clears deletedAt and clears lastDeletedSubjectId',
      () async {
        final now = DateTime(2026, 3, 1, 10, 0);
        final subject = SubjectEntity(
          id: 'sub_to_restore',
          name: 'Art History',
          createdAt: now,
          updatedAt: now,
          deletedAt: now,
        );
        await fakeRepo.saveSubject(subject);

        await controller.deleteSubject('sub_to_restore');
        await controller.restoreSubject('sub_to_restore');

        expect(controller.lastDeletedSubjectId, isNull);
        final active = await fakeRepo.getSubjects();
        expect(active.length, 1);
        expect(active.first.isDeleted, isFalse);
      },
    );

    test('reorderSubjects updates sortOrder across subject list', () async {
      final now = DateTime(2026, 3, 1, 10, 0);
      final sub1 = SubjectEntity(
        id: 's1',
        name: 'Sub 1',
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      );
      final sub2 = SubjectEntity(
        id: 's2',
        name: 'Sub 2',
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      );
      final sub3 = SubjectEntity(
        id: 's3',
        name: 'Sub 3',
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
      );
      await fakeRepo.saveSubjects([sub1, sub2, sub3]);

      await controller.reorderSubjects(['s2', 's3', 's1']);

      final subjects = await fakeRepo.getSubjects();
      final map = {for (final s in subjects) s.id: s.sortOrder};
      expect(map['s2'], 0);
      expect(map['s3'], 1);
      expect(map['s1'], 2);
    });
  });
}
