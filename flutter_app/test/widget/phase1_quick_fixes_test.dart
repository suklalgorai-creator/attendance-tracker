import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_app/app/app.dart';
import 'package:flutter_app/core/providers/notification_providers.dart';
import 'package:flutter_app/core/providers/repository_providers.dart';
import 'package:flutter_app/core/services/notification_service.dart';
import 'package:flutter_app/features/notes/domain/entities/note_entity.dart';
import 'package:flutter_app/features/notes/domain/repositories/notes_repository.dart';
import 'package:flutter_app/features/notes/presentation/pages/notes_page.dart';
import 'package:flutter_app/shared/widgets/app_drawer.dart';
import 'package:flutter_app/shared/widgets/app_header.dart';
import 'package:flutter_app/shared/widgets/streak_popup_dialog.dart';

class _FakeNotesRepository implements NotesRepository {
  final List<NoteEntity> _notes;
  _FakeNotesRepository(this._notes);

  @override
  Future<void> clearAllNotes() async => _notes.clear();

  @override
  Future<void> deleteNote(String id) async =>
      _notes.removeWhere((n) => n.id == id);

  @override
  Future<NoteEntity?> getNoteById(String id) async => _notes
      .cast<NoteEntity?>()
      .firstWhere((n) => n?.id == id, orElse: () => null);

  @override
  Future<List<NoteEntity>> getNotes() async => List.unmodifiable(_notes);

  @override
  Future<void> saveNote(NoteEntity note) async {
    _notes.removeWhere((n) => n.id == note.id);
    _notes.add(note);
  }

  @override
  Future<void> saveNotes(List<NoteEntity> notes) async {
    _notes
      ..clear()
      ..addAll(notes);
  }

  @override
  Stream<List<NoteEntity>> watchNotes() =>
      Stream.value(List.unmodifiable(_notes));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 1 Quick Fixes Widget Tests', () {
    testWidgets('AppHeader streak badge opens StreakPopupDialog on tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: AppHeader(streak: 7))),
        ),
      );

      final streakButton = find.byKey(const Key('header_streak_button'));
      expect(streakButton, findsOneWidget);

      await tester.tap(streakButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byType(StreakPopupDialog), findsOneWidget);
      expect(find.text('7 Day Streak!'), findsOneWidget);
    });

    testWidgets(
      'AttendanceApp preserves MediaQuery accessibleNavigation flag',
      (tester) async {
        bool? observedAccessibleNav;

        await tester.pumpWidget(
          ProviderScope(
            child: MediaQuery(
              data: const MediaQueryData(accessibleNavigation: true),
              child: Builder(
                builder: (context) {
                  return AttendanceApp();
                },
              ),
            ),
          ),
        );
        await tester.pump();

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.builder, isNull);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(accessibleNavigation: true),
            child: Builder(
              builder: (ctx) {
                observedAccessibleNav = MediaQuery.accessibleNavigationOf(ctx);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(observedAccessibleNav, isTrue);
      },
    );

    testWidgets('NotesPage renders MarkdownBody and clean alarm emoji', (
      tester,
    ) async {
      final now = DateTime(2026, 11, 25, 14, 30);
      final fakeRepo = _FakeNotesRepository([
        NoteEntity(
          id: 'n1',
          content: '# Exam\n**Bring ID card**',
          reminderDate: now,
          createdAt: now,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesRepositoryProvider.overrideWithValue(fakeRepo),
            notificationServiceProvider.overrideWithValue(
              DefaultNotificationService(),
            ),
          ],
          child: const MaterialApp(home: NotesPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.textContaining('⏰'), findsOneWidget);
      expect(find.textContaining('â °'), findsNothing);
    });

    testWidgets('AppDrawer displays Send Feedback item', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(drawer: AppDrawer(), body: SizedBox.shrink()),
          ),
        ),
      );

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Send Feedback'),
        100.0,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text('Send Feedback'));
      await tester.pumpAndSettle();
      expect(find.text('Send Feedback'), findsOneWidget);

      await tester.tap(find.text('Send Feedback'));
      await tester.pumpAndSettle();
      expect(scaffoldState.isDrawerOpen, isFalse);
    });
  });
}
