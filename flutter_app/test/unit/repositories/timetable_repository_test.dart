import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';
import 'package:flutter_app/features/subjects/domain/repositories/subject_repository.dart';
import 'package:flutter_app/features/timetable/data/repositories/timetable_repository_impl.dart';

class FakeSubjectRepository implements SubjectRepository {
  final Map<String, SubjectEntity> _subjects = {};

  void add(SubjectEntity subject) {
    _subjects[subject.id] = subject;
  }

  @override
  Future<SubjectEntity?> getSubjectById(String id) async => _subjects[id];

  @override
  Future<List<SubjectEntity>> getSubjects({bool includeDeleted = false}) async =>
      _subjects.values.where((s) => includeDeleted || !s.isDeleted).toList();

  @override
  Stream<List<SubjectEntity>> watchSubjects({bool includeDeleted = false}) =>
      Stream.value(_subjects.values.toList());

  @override
  Future<void> saveSubject(SubjectEntity subject) async => _subjects[subject.id] = subject;

  @override
  Future<void> saveSubjects(List<SubjectEntity> subjects) async {
    for (final s in subjects) {
      _subjects[s.id] = s;
    }
  }

  @override
  Future<void> deleteSubject(String id) async {}

  @override
  Future<void> hardDeleteSubject(String id) async => _subjects.remove(id);

  @override
  Future<void> reorderSubjects(List<String> orderedIds) async {}

  @override
  Future<void> restoreSubject(String id) async {}
}

void main() {
  group('TimetableRepositoryImpl Unit Tests', () {
    late Directory tempDir;
    late Box testBox;
    late FakeSubjectRepository fakeSubjectRepo;
    late TimetableRepositoryImpl repository;

    final now = DateTime(2026, 3, 1, 10, 0);

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_timetable_test_');
      Hive.init(tempDir.path);
      testBox = await Hive.openBox('settings_box');
      fakeSubjectRepo = FakeSubjectRepository();
      fakeSubjectRepo.add(
        SubjectEntity(
          id: 'sub-math',
          name: 'Mathematics',
          createdAt: now,
          updatedAt: now,
        ),
      );
      fakeSubjectRepo.add(
        SubjectEntity(
          id: 'sub-phy',
          name: 'Physics',
          createdAt: now,
          updatedAt: now,
        ),
      );

      repository = TimetableRepositoryImpl(
        box: testBox,
        subjectRepository: fakeSubjectRepo,
      );
    });

    tearDown(() async {
      await testBox.close();
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('getTimetable returns empty map initially', () async {
      final timetable = await repository.getTimetable();
      expect(timetable, isEmpty);
    });

    test('addSession successfully resolves subject name and appends to day', () async {
      await repository.addSession(1, 'sub-math');

      final timetable = await repository.getTimetable();
      expect(timetable.containsKey(1), isTrue);
      expect(timetable[1]!.length, 1);

      final session = timetable[1]!.first;
      expect(session.subjectId, 'sub-math');
      expect(session.label, 'Mathematics');
      expect(session.dayOfWeek, 1);
      expect(session.active, isTrue);
      expect(session.isDeleted, isFalse);
    });

    test('addSession uses custom label when provided', () async {
      await repository.addSession(2, 'sub-phy', label: 'Physics Honors');

      final timetable = await repository.getTimetable();
      expect(timetable[2]!.first.label, 'Physics Honors');
    });

    test('addSession ignores invalid day index', () async {
      await repository.addSession(-1, 'sub-math');
      await repository.addSession(7, 'sub-math');

      final timetable = await repository.getTimetable();
      expect(timetable, isEmpty);
    });

    test('removeSession performs soft deletion', () async {
      await repository.addSession(1, 'sub-math');
      final initial = await repository.getTimetable();
      final sessionId = initial[1]!.first.id;

      await repository.removeSession(1, sessionId);

      // Active timetable excludes soft-deleted session
      final activeTimetable = await repository.getTimetable();
      expect(activeTimetable[1], isEmpty);

      // Full timetable includes soft-deleted session with deletedAt
      final fullTimetable = await repository.getTimetable(includeDeleted: true);
      expect(fullTimetable[1]!.length, 1);
      expect(fullTimetable[1]!.first.isDeleted, isTrue);
      expect(fullTimetable[1]!.first.deletedAt, isNotNull);
      expect(fullTimetable[1]!.first.active, isFalse);
    });

    test('removeSession handles nonexistent sessionId gracefully', () async {
      await repository.addSession(1, 'sub-math');
      await repository.removeSession(1, 'non-existent-id');

      final timetable = await repository.getTimetable();
      expect(timetable[1]!.length, 1);
    });

    test('clearTimetable removes all sessions from box', () async {
      await repository.addSession(1, 'sub-math');
      await repository.addSession(2, 'sub-phy');

      await repository.clearTimetable();

      final timetable = await repository.getTimetable(includeDeleted: true);
      expect(timetable, isEmpty);
    });

    test('watchTimetable emits reactive updates', () async {
      final stream = repository.watchTimetable();

      expect(
        stream,
        emitsInOrder([
          isEmpty, // initial
          predicate<Map<int, dynamic>>((m) => m.containsKey(1) && m[1].length == 1),
        ]),
      );

      // Allow initial yield
      await Future.delayed(const Duration(milliseconds: 20));
      await repository.addSession(1, 'sub-math');
    });
  });
}
