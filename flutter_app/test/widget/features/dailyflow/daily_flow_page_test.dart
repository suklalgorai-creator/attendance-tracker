import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/providers/notification_providers.dart';
import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/core/services/notification_service.dart';
import 'package:flutter_app/features/dailyflow/domain/entities/daily_task_entity.dart';
import 'package:flutter_app/features/dailyflow/domain/repositories/daily_flow_repository.dart';
import 'package:flutter_app/features/dailyflow/presentation/pages/daily_flow_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _InMemoryDailyFlowRepository implements DailyFlowRepository {
  final List<DailyTaskEntity> _items;
  final StreamController<List<DailyTaskEntity>> _controller =
      StreamController<List<DailyTaskEntity>>.broadcast();

  _InMemoryDailyFlowRepository([List<DailyTaskEntity>? initial])
    : _items = List<DailyTaskEntity>.from(initial ?? const []);

  @override
  Future<void> clearAllTasks() async {
    _items.clear();
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<void> deleteTask(String id) async {
    _items.removeWhere((t) => t.id == id);
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<DailyTaskEntity?> getTaskById(String id) async {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<List<DailyTaskEntity>> getTasks() async => List.unmodifiable(_items);

  @override
  Future<void> saveTask(DailyTaskEntity task) async {
    final idx = _items.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      _items[idx] = task;
    } else {
      _items.add(task);
    }
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<void> saveTasks(List<DailyTaskEntity> tasks) async {
    _items
      ..clear()
      ..addAll(tasks);
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Stream<List<DailyTaskEntity>> watchTasks() async* {
    yield List.unmodifiable(_items);
    yield* _controller.stream;
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildApp(DailyFlowRepository repo) {
    return ProviderScope(
      overrides: [
        dailyFlowRepositoryProvider.overrideWithValue(repo),
        notificationServiceProvider.overrideWithValue(
          DefaultNotificationService(),
        ),
        subjectsStreamProvider.overrideWith((ref) => Stream.value(const [])),
        timetableStreamProvider.overrideWith((ref) => Stream.value(const {})),
        attendanceRecordsStreamProvider.overrideWith(
          (ref) => Stream.value(const []),
        ),
      ],
      child: const MaterialApp(home: DailyFlowPage()),
    );
  }

  group('DailyFlowPage Widget Tests', () {
    testWidgets('renders empty state and inline quick-add bar', (tester) async {
      final repo = _InMemoryDailyFlowRepository();
      await tester.pumpWidget(buildApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('DailyFlow'), findsOneWidget);
      expect(find.text('No classes or tasks planned'), findsOneWidget);
      expect(find.text('Add a task...'), findsOneWidget);
      expect(find.byTooltip('Quick add task'), findsOneWidget);
      expect(find.byTooltip('Add with reminder & options'), findsOneWidget);
    });

    testWidgets(
      'quick-adds task inline and completes via 1-tap checkbox cleanly at 320px',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repo = _InMemoryDailyFlowRepository();
        await tester.pumpWidget(buildApp(repo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'Revise Compiler Design',
        );
        await tester.tap(find.byTooltip('Quick add task'));
        await tester.pumpAndSettle();

        expect(find.text('Revise Compiler Design'), findsOneWidget);
        expect(find.text('0/1 done'), findsOneWidget);

        // Toggle done with 1-tap checkbox
        await tester.tap(find.byIcon(Icons.radio_button_unchecked_rounded));
        await tester.pumpAndSettle();

        expect(find.text('1/1 done'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'opens clean task & reminder dialog without extra timer chips',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final repo = _InMemoryDailyFlowRepository();
        await tester.pumpWidget(buildApp(repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Add with reminder & options'));
        await tester.pumpAndSettle();

        expect(find.text('New Task'), findsOneWidget);
        expect(find.text('Set Reminder'), findsOneWidget);
        expect(find.text('Estimated Focus'), findsNothing);
        expect(find.text('15m'), findsNothing);
        expect(find.text('Priority'), findsNothing);
        expect(find.text('Repeat'), findsNothing);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
