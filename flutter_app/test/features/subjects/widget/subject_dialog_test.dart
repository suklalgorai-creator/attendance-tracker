import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/features/subjects/domain/entities/subject_entity.dart';
import 'package:flutter_app/features/subjects/domain/repositories/subject_repository.dart';
import 'package:flutter_app/features/subjects/presentation/widgets/subject_dialog.dart';

class DialogTestSubjectRepository implements SubjectRepository {
  final List<SubjectEntity> subjects = [];
  final _controller = StreamController<List<SubjectEntity>>.broadcast();

  void _notify() => _controller.add(List.unmodifiable(subjects));

  @override
  Future<List<SubjectEntity>> getSubjects({bool includeDeleted = false}) async {
    if (includeDeleted) return List.from(subjects);
    return subjects.where((s) => !s.isDeleted).toList();
  }

  @override
  Stream<List<SubjectEntity>> watchSubjects({
    bool includeDeleted = false,
  }) async* {
    yield List.from(subjects);
    yield* _controller.stream;
  }

  @override
  Future<SubjectEntity?> getSubjectById(String id) async {
    final match = subjects.where((s) => s.id == id);
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<void> saveSubject(SubjectEntity subject) async {
    final index = subjects.indexWhere((s) => s.id == subject.id);
    if (index >= 0) {
      subjects[index] = subject;
    } else {
      subjects.add(subject);
    }
    _notify();
  }

  @override
  Future<void> saveSubjects(List<SubjectEntity> list) async {
    subjects.clear();
    subjects.addAll(list);
    _notify();
  }

  @override
  Future<void> deleteSubject(String id) async {
    final index = subjects.indexWhere((s) => s.id == id);
    if (index >= 0) {
      subjects[index] = subjects[index].copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> restoreSubject(String id) async {
    final index = subjects.indexWhere((s) => s.id == id);
    if (index >= 0) {
      subjects[index] = subjects[index].copyWith(
        clearDeletedAt: true,
        updatedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> hardDeleteSubject(String id) async {
    subjects.removeWhere((s) => s.id == id);
    _notify();
  }

  @override
  Future<void> reorderSubjects(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      final id = orderedIds[i];
      final idx = subjects.indexWhere((s) => s.id == id);
      if (idx >= 0) {
        subjects[idx] = subjects[idx].copyWith(sortOrder: i);
      }
    }
    _notify();
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createTestWidget({
    required DialogTestSubjectRepository repository,
    SubjectEntity? subject,
    VoidCallback? onSaved,
    VoidCallback? onDeleted,
  }) {
    return ProviderScope(
      overrides: [subjectRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(
          body: SubjectDialog(
            subject: subject,
            onSaved: onSaved,
            onDeleted: onDeleted,
          ),
        ),
      ),
    );
  }

  group('SubjectDialog Widget Tests', () {
    late DialogTestSubjectRepository repository;
    final now = DateTime(2026, 3, 1, 10, 0);

    setUp(() {
      repository = DialogTestSubjectRepository();
    });

    void setTallScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('Renders in Add Mode with empty fields and no delete button', (
      tester,
    ) async {
      setTallScreen(tester);

      await tester.pumpWidget(createTestWidget(repository: repository));
      await tester.pumpAndSettle();

      expect(find.text('Add Subject'), findsOneWidget);
      expect(find.text('SUBJECT NAME'), findsOneWidget);
      expect(find.text('SUBJECT CODE (OPTIONAL)'), findsOneWidget);
      expect(find.text('COLOR ACCENT'), findsOneWidget);
      expect(find.text('ICON'), findsOneWidget);
      expect(find.text('CUSTOM TARGET'), findsOneWidget);
      expect(find.byKey(const Key('save_subject_button')), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byKey(const Key('delete_subject_button')), findsNothing);
    });

    testWidgets(
      'Renders in Edit Mode with pre-populated fields and delete button',
      (tester) async {
        setTallScreen(tester);

        final subject = SubjectEntity(
          id: 'sub_edit',
          name: 'Calculus III',
          code: 'MATH301',
          color: '#3B82F6',
          icon: 'calculate',
          targetPercentage: 85.0,
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          createTestWidget(repository: repository, subject: subject),
        );
        await tester.pumpAndSettle();

        expect(find.text('Edit Subject'), findsOneWidget);
        expect(find.text('Calculus III'), findsOneWidget);
        expect(find.text('MATH301'), findsOneWidget);
        expect(find.text('Update'), findsOneWidget);
        expect(find.byKey(const Key('delete_subject_button')), findsOneWidget);
        expect(find.text('85%'), findsWidgets);
      },
    );

    testWidgets('Validation: empty name triggers inline error', (tester) async {
      setTallScreen(tester);

      await tester.pumpWidget(createTestWidget(repository: repository));
      await tester.pumpAndSettle();

      // Tap Save button without entering name
      await tester.tap(find.byKey(const Key('save_subject_button')));
      await tester.pumpAndSettle();

      expect(find.text('Subject name is required'), findsOneWidget);
      expect(repository.subjects.isEmpty, isTrue);
    });

    testWidgets('Color palette: selecting swatch updates chosen color', (
      tester,
    ) async {
      setTallScreen(tester);

      await tester.pumpWidget(createTestWidget(repository: repository));
      await tester.pumpAndSettle();

      // Tap Blue swatch #3B82F6
      final blueSwatch = find.byKey(const Key('color_swatch_#3B82F6'));
      expect(blueSwatch, findsOneWidget);
      await tester.tap(blueSwatch);
      await tester.pumpAndSettle();

      // Enter name and save
      await tester.enterText(
        find.byKey(const Key('subject_name_field')),
        'Operating Systems',
      );
      await tester.tap(find.byKey(const Key('save_subject_button')));
      await tester.pumpAndSettle();

      expect(repository.subjects.length, 1);
      expect(repository.subjects.first.color, '#3B82F6');
    });

    testWidgets('Icon selector: selecting icon updates chosen icon', (
      tester,
    ) async {
      setTallScreen(tester);

      await tester.pumpWidget(createTestWidget(repository: repository));
      await tester.pumpAndSettle();

      // Tap Computer icon chip
      final computerIcon = find.byKey(const Key('icon_chip_computer'));
      expect(computerIcon, findsOneWidget);
      await tester.tap(computerIcon);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('subject_name_field')),
        'Web Engineering',
      );
      await tester.tap(find.byKey(const Key('save_subject_button')));
      await tester.pumpAndSettle();

      expect(repository.subjects.length, 1);
      expect(repository.subjects.first.icon, 'computer');
    });

    testWidgets(
      'Custom target toggle enables slider and saves target percentage',
      (tester) async {
        setTallScreen(tester);

        await tester.pumpWidget(createTestWidget(repository: repository));
        await tester.pumpAndSettle();

        // Initially target slider is not visible
        expect(find.byKey(const Key('target_slider')), findsNothing);

        // Toggle switch on
        await tester.tap(find.byKey(const Key('custom_target_toggle')));
        await tester.pumpAndSettle();

        // Target slider is now visible
        expect(find.byKey(const Key('target_slider')), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('subject_name_field')),
          'Linear Algebra',
        );
        await tester.tap(find.byKey(const Key('save_subject_button')));
        await tester.pumpAndSettle();

        expect(repository.subjects.length, 1);
        expect(repository.subjects.first.targetPercentage, 75.0);
      },
    );

    testWidgets(
      'Tapping Delete opens confirmation dialog; cancel dismisses dialog',
      (tester) async {
        setTallScreen(tester);

        final subject = SubjectEntity(
          id: 'sub_del',
          name: 'Chemistry',
          createdAt: now,
          updatedAt: now,
        );
        await repository.saveSubject(subject);

        await tester.pumpWidget(
          createTestWidget(repository: repository, subject: subject),
        );
        await tester.pumpAndSettle();

        // Tap Delete button
        await tester.tap(find.byKey(const Key('delete_subject_button')));
        await tester.pumpAndSettle();

        expect(find.text('Delete Subject'), findsWidgets);
        expect(
          find.textContaining('Are you sure you want to delete "Chemistry"?'),
          findsOneWidget,
        );

        // Tap Cancel in confirmation dialog
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();

        // Subject was not deleted
        final active = await repository.getSubjects();
        expect(active.length, 1);
      },
    );

    testWidgets('Tapping Delete and confirming performs soft-delete', (
      tester,
    ) async {
      setTallScreen(tester);

      final subject = SubjectEntity(
        id: 'sub_del_confirm',
        name: 'Biology Lab',
        createdAt: now,
        updatedAt: now,
      );
      await repository.saveSubject(subject);

      bool deletedCallbackCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          repository: repository,
          subject: subject,
          onDeleted: () => deletedCallbackCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete_subject_button')));
      await tester.pumpAndSettle();

      // Confirm Delete
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(deletedCallbackCalled, isTrue);
      final active = await repository.getSubjects();
      expect(active.isEmpty, isTrue);
      final all = await repository.getSubjects(includeDeleted: true);
      expect(all.first.isDeleted, isTrue);
    });

    testWidgets(
      'Responsive rendering: does not overflow on compact viewport Size(320, 568)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final subject = SubjectEntity(
          id: 'sub_compact',
          name: 'Algorithms',
          targetPercentage: 80.0,
          createdAt: now,
          updatedAt: now,
        );

        await tester.pumpWidget(
          createTestWidget(repository: repository, subject: subject),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Edit Subject'), findsOneWidget);
      },
    );
  });
}
