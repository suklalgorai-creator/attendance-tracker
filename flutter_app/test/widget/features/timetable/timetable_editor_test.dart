import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';
import 'package:flutter_app/features/timetable/domain/entities/timetable_session_entity.dart';
import 'package:flutter_app/features/timetable/presentation/widgets/timetable_editor.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final now = DateTime(2026, 3, 1, 10, 0);

  final mockSubjects = [
    SubjectEntity(
      id: 'sub-math',
      name: 'Mathematics',
      createdAt: now,
      updatedAt: now,
    ),
    SubjectEntity(
      id: 'sub-phy',
      name: 'Physics',
      createdAt: now,
      updatedAt: now,
    ),
  ];

  Widget buildWidget({
    required List<int> classDays,
    required Map<int, List<TimetableSessionEntity>> timetable,
    required List<SubjectEntity> subjects,
    void Function(int, String)? onAddSession,
    void Function(int, String)? onRemoveSession,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TimetableEditor(
            classDays: classDays,
            timetable: timetable,
            subjects: subjects,
            onAddSession: onAddSession ?? (day, subjectId) {},
            onRemoveSession: onRemoveSession ?? (day, sessionId) {},
          ),
        ),
      ),
    );
  }

  group('TimetableEditor Widget Tests', () {
    testWidgets('renders only configured active classDays', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          classDays: [1, 3, 5], // Mon, Wed, Fri
          timetable: const {},
          subjects: mockSubjects,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MON'), findsOneWidget);
      expect(find.text('WED'), findsOneWidget);
      expect(find.text('FRI'), findsOneWidget);

      expect(find.text('SUN'), findsNothing);
      expect(find.text('TUE'), findsNothing);
      expect(find.text('THU'), findsNothing);
      expect(find.text('SAT'), findsNothing);
    });

    testWidgets('renders existing sessions and invokes onRemoveSession on tap', (tester) async {
      int? removedDay;
      String? removedSessionId;

      final timetable = {
        1: [
          TimetableSessionEntity(
            id: 'session-101',
            subjectId: 'sub-math',
            label: 'Mathematics',
            dayOfWeek: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      };

      await tester.pumpWidget(
        buildWidget(
          classDays: [1],
          timetable: timetable,
          subjects: mockSubjects,
          onRemoveSession: (day, id) {
            removedDay = day;
            removedSessionId = id;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mathematics'), findsWidgets);

      // Find and tap remove button
      final removeButton = find.bySemanticsLabel('Remove Mathematics');
      expect(removeButton, findsOneWidget);

      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      expect(removedDay, 1);
      expect(removedSessionId, 'session-101');
    });

    testWidgets('allows adding session and invokes onAddSession', (tester) async {
      int? addedDay;
      String? addedSubjectId;

      await tester.pumpWidget(
        buildWidget(
          classDays: [1],
          timetable: const {},
          subjects: mockSubjects,
          onAddSession: (day, subId) {
            addedDay = day;
            addedSubjectId = subId;
          },
        ),
      );
      await tester.pumpAndSettle();

      final addSessionButton = find.text('Add session');
      expect(addSessionButton, findsOneWidget);

      await tester.tap(addSessionButton);
      await tester.pumpAndSettle();

      expect(addedDay, 1);
      expect(addedSubjectId, 'sub-math');
    });

    testWidgets('shows "Create a subject first." when subjects list is empty', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          classDays: [1, 2],
          timetable: const {},
          subjects: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create a subject first.'), findsNWidgets(2));
      expect(find.text('Add session'), findsNothing);
    });

    testWidgets('shows empty state when classDays is empty', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          classDays: const [],
          timetable: const {},
          subjects: mockSubjects,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No class days configured'), findsOneWidget);
    });

    testWidgets('320px narrow screen width renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final timetable = {
        1: [
          TimetableSessionEntity(
            id: 'sess-1',
            subjectId: 'sub-math',
            label: 'Advanced Mathematics and Calculus',
            dayOfWeek: 1,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        2: [
          TimetableSessionEntity(
            id: 'sess-2',
            subjectId: 'sub-phy',
            label: 'Theoretical Physics Lab',
            dayOfWeek: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      };

      await tester.pumpWidget(
        buildWidget(
          classDays: [1, 2, 3, 4, 5],
          timetable: timetable,
          subjects: mockSubjects,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('MON'), findsOneWidget);
      expect(find.text('TUE'), findsOneWidget);
    });
  });
}
