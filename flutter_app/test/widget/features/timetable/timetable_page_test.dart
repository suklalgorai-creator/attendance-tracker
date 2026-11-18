import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';
import 'package:flutter_app/features/timetable/domain/entities/timetable_session_entity.dart';
import 'package:flutter_app/features/timetable/domain/repositories/timetable_repository.dart';
import 'package:flutter_app/features/timetable/presentation/pages/timetable_page.dart';

class FakeTimetableRepo implements TimetableRepository {
  final Map<int, List<TimetableSessionEntity>> data;
  int addSessionCount = 0;
  int removeSessionCount = 0;

  FakeTimetableRepo({Map<int, List<TimetableSessionEntity>>? initial})
      : data = initial != null ? Map.from(initial) : {};

  @override
  Future<Map<int, List<TimetableSessionEntity>>> getTimetable({bool includeDeleted = false}) async => data;

  @override
  Stream<Map<int, List<TimetableSessionEntity>>> watchTimetable({bool includeDeleted = false}) =>
      Stream.value(data);

  @override
  Future<void> addSession(int dayOfWeek, String subjectId, {String? label}) async {
    addSessionCount++;
  }

  @override
  Future<void> removeSession(int dayOfWeek, String sessionId) async {
    removeSessionCount++;
  }

  @override
  Future<void> clearTimetable() async => data.clear();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final now = DateTime(2026, 3, 1, 10, 0);

  final mockSubjects = [
    SubjectEntity(
      id: 'sub-cs',
      name: 'Computer Science',
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final mockSettings = const UserSettingsEntity(
    classDays: [1, 2], // Mon, Tue
  );

  Widget buildPage({
    required FakeTimetableRepo repo,
    Map<int, List<TimetableSessionEntity>>? timetableData,
  }) {
    return ProviderScope(
      overrides: [
        timetableRepositoryProvider.overrideWithValue(repo),
        timetableStreamProvider.overrideWith((ref) => Stream.value(timetableData ?? repo.data)),
        subjectsStreamProvider.overrideWith((ref) => Stream.value(mockSubjects)),
        settingsStreamProvider.overrideWith((ref) => Stream.value(mockSettings)),
      ],
      child: const MaterialApp(
        home: TimetablePage(),
      ),
    );
  }

  group('TimetablePage Widget Tests', () {
    testWidgets('renders page title, weekly schedule card, and class days', (tester) async {
      final repo = FakeTimetableRepo();

      await tester.pumpWidget(buildPage(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('WEEKLY SCHEDULE'), findsOneWidget);
      expect(find.text('MON'), findsOneWidget);
      expect(find.text('TUE'), findsOneWidget);
      expect(find.text('Add session'), findsNWidgets(2));
    });

    testWidgets('tapping Add session calls timetableRepository.addSession', (tester) async {
      final repo = FakeTimetableRepo();

      await tester.pumpWidget(buildPage(repo: repo));
      await tester.pumpAndSettle();

      final addBtn = find.text('Add session').first;
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(repo.addSessionCount, 1);
    });

    testWidgets('tapping remove session calls timetableRepository.removeSession', (tester) async {
      final initialData = {
        1: [
          TimetableSessionEntity(
            id: 'sess-remove',
            subjectId: 'sub-cs',
            label: 'Computer Science',
            dayOfWeek: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      };
      final repo = FakeTimetableRepo(initial: initialData);

      await tester.pumpWidget(buildPage(repo: repo, timetableData: initialData));
      await tester.pumpAndSettle();

      final removeBtn = find.bySemanticsLabel('Remove Computer Science');
      expect(removeBtn, findsOneWidget);

      await tester.tap(removeBtn);
      await tester.pumpAndSettle();

      expect(repo.removeSessionCount, 1);
    });
  });
}
