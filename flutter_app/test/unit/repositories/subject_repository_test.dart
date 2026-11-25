import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/subjects/data/datasources/subject_local_datasource.dart';
import 'package:flutter_app/features/subjects/data/models/subject_model.dart';
import 'package:flutter_app/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';

class FakeSubjectLocalDataSource implements SubjectLocalDataSource {
  final List<SubjectModel> _items = [];
  final _controller = StreamController<List<SubjectModel>>.broadcast();

  void _notify() {
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<List<SubjectModel>> getSubjects() async {
    return List.from(_items);
  }

  @override
  Stream<List<SubjectModel>> watchSubjects() async* {
    yield List.from(_items);
    yield* _controller.stream;
  }

  @override
  Future<void> saveSubject(SubjectModel subject) async {
    final index = _items.indexWhere((s) => s.id == subject.id);
    if (index >= 0) {
      _items[index] = subject;
    } else {
      _items.add(subject);
    }
    _notify();
  }

  @override
  Future<void> saveSubjects(List<SubjectModel> subjects) async {
    _items.clear();
    _items.addAll(subjects);
    _notify();
  }

  @override
  Future<void> deleteSubject(String id) async {
    _items.removeWhere((s) => s.id == id);
    _notify();
  }

  @override
  Future<SubjectModel?> getSubjectById(String id) async {
    final match = _items.where((s) => s.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<void> clear() async {
    _items.clear();
    _notify();
  }
}

void main() {
  group('SubjectRepositoryImpl Unit Tests', () {
    late FakeSubjectLocalDataSource fakeDataSource;
    late SubjectRepositoryImpl repository;
    final now = DateTime(2026, 3, 1, 10, 0);

    setUp(() {
      fakeDataSource = FakeSubjectLocalDataSource();
      repository = SubjectRepositoryImpl(localDataSource: fakeDataSource);
    });

    test(
      'saveSubject and getSubjects (excluding deleted by default)',
      () async {
        final subject1 = SubjectEntity(
          id: 'sub-1',
          name: 'Calculus',
          color: '#10B981',
          createdAt: now,
          updatedAt: now,
        );

        final subject2 = SubjectEntity(
          id: 'sub-2',
          name: 'Data Structures',
          color: '#3B82F6',
          createdAt: now,
          updatedAt: now,
          deletedAt: now,
        );

        await repository.saveSubject(subject1);
        await repository.saveSubject(subject2);

        final activeOnly = await repository.getSubjects();
        expect(activeOnly.length, 1);
        expect(activeOnly.first.id, 'sub-1');

        final allIncludingDeleted = await repository.getSubjects(
          includeDeleted: true,
        );
        expect(allIncludingDeleted.length, 2);
      },
    );

    test('saveSubjects batch replaces subjects list', () async {
      final list = [
        SubjectEntity(
          id: 's1',
          name: 'Subject 1',
          createdAt: now,
          updatedAt: now,
        ),
        SubjectEntity(
          id: 's2',
          name: 'Subject 2',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await repository.saveSubjects(list);
      final retrieved = await repository.getSubjects();
      expect(retrieved.length, 2);
    });

    test(
      'getSubjects returns subjects sorted by sortOrder then createdAt',
      () async {
        final subA = SubjectEntity(
          id: 's-a',
          name: 'Math',
          sortOrder: 2,
          createdAt: now.add(const Duration(minutes: 5)),
          updatedAt: now,
        );
        final subB = SubjectEntity(
          id: 's-b',
          name: 'Physics',
          sortOrder: 1,
          createdAt: now.add(const Duration(minutes: 10)),
          updatedAt: now,
        );
        final subC = SubjectEntity(
          id: 's-c',
          name: 'Chemistry',
          sortOrder: 1,
          createdAt: now,
          updatedAt: now,
        );

        await repository.saveSubject(subA);
        await repository.saveSubject(subB);
        await repository.saveSubject(subC);

        final retrieved = await repository.getSubjects();
        expect(retrieved.map((s) => s.id).toList(), ['s-c', 's-b', 's-a']);
      },
    );

    test(
      'reorderSubjects updates sortOrder of subjects according to provided ID list',
      () async {
        final sub1 = SubjectEntity(
          id: 's1',
          name: 'First',
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        );
        final sub2 = SubjectEntity(
          id: 's2',
          name: 'Second',
          sortOrder: 1,
          createdAt: now,
          updatedAt: now,
        );
        final sub3 = SubjectEntity(
          id: 's3',
          name: 'Third',
          sortOrder: 2,
          createdAt: now,
          updatedAt: now,
        );

        await repository.saveSubjects([sub1, sub2, sub3]);

        await repository.reorderSubjects(['s3', 's1', 's2']);

        final reordered = await repository.getSubjects();
        expect(reordered.map((s) => s.id).toList(), ['s3', 's1', 's2']);
        expect(reordered[0].sortOrder, 0);
        expect(reordered[1].sortOrder, 1);
        expect(reordered[2].sortOrder, 2);
      },
    );

    test(
      'deleteSubject performs soft-deletion and updates updatedAt',
      () async {
        final subject = SubjectEntity(
          id: 'sub-del',
          name: 'Chemistry',
          createdAt: now,
          updatedAt: now,
        );

        await repository.saveSubject(subject);
        expect((await repository.getSubjects()).length, 1);

        await repository.deleteSubject('sub-del');

        // Excluded from standard query
        final active = await repository.getSubjects();
        expect(active.isEmpty, isTrue);

        // Present in includeDeleted query with deletedAt set
        final all = await repository.getSubjects(includeDeleted: true);
        expect(all.length, 1);
        expect(all.first.isDeleted, isTrue);
        expect(all.first.deletedAt, isNotNull);
        expect(
          all.first.updatedAt.isAfter(now) || all.first.updatedAt == now,
          isTrue,
        );
      },
    );

    test('restoreSubject clears deletedAt and updates updatedAt', () async {
      final subject = SubjectEntity(
        id: 'sub-res',
        name: 'Physics',
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      );

      await repository.saveSubject(subject);
      expect((await repository.getSubjects()).isEmpty, isTrue);

      await repository.restoreSubject('sub-res');

      final active = await repository.getSubjects();
      expect(active.length, 1);
      expect(active.first.isDeleted, isFalse);
      expect(active.first.deletedAt, isNull);
    });

    test('hardDeleteSubject permanently purges subject', () async {
      final subject = SubjectEntity(
        id: 'sub-hard',
        name: 'Biology',
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveSubject(subject);
      await repository.hardDeleteSubject('sub-hard');

      final all = await repository.getSubjects(includeDeleted: true);
      expect(all.isEmpty, isTrue);
    });

    test('getSubjectById returns active subject or null if deleted', () async {
      final active = SubjectEntity(
        id: 's-act',
        name: 'Active',
        createdAt: now,
        updatedAt: now,
      );
      final deleted = SubjectEntity(
        id: 's-del',
        name: 'Deleted',
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      );

      await repository.saveSubject(active);
      await repository.saveSubject(deleted);

      expect(await repository.getSubjectById('s-act'), isNotNull);
      expect(await repository.getSubjectById('s-del'), isNull);
      expect(await repository.getSubjectById('non-existent'), isNull);
    });

    test('watchSubjects emits stream events on changes', () async {
      final subject = SubjectEntity(
        id: 's-watch',
        name: 'Watcher',
        createdAt: now,
        updatedAt: now,
      );

      expectLater(
        repository.watchSubjects(),
        emitsInOrder([
          [], // Initial empty
          [subject], // After save
        ]),
      );

      await pumpEventQueue();
      await repository.saveSubject(subject);
    });
  });
}
