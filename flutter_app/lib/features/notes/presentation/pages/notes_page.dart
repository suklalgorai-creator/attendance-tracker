import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/notification_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/note_entity.dart';
import '../widgets/note_card.dart';
import '../widgets/note_editor_dialog.dart';

/// Sticky Notes CRUD page matching `react_app/src/pages/NotesPage.jsx`.
///
/// Ownership: Notes Feature
// ==========================================
// NOTES - Sticky Notes Screen
// ==========================================
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sticky Notes Page'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Unable to load notes.',
            style: AppTypography.bodyMedium(AppColors.penRed),
          ),
        ),
        data: (notes) => _NotesBody(notes: notes),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create note',
        backgroundColor: AppColors.inkGreen,
        foregroundColor: Colors.white,
        onPressed: () => _createNote(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _createNote(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<NoteEntity>(
      context: context,
      builder: (_) => const NoteEditorDialog(),
    );
    if (result != null) {
      await ref.read(notesRepositoryProvider).saveNote(result);
      final notifier = ref.read(notificationServiceProvider);
      if (result.reminderDate != null) {
        await notifier.scheduleNoteReminder(
          noteId: result.id,
          content: result.content,
          reminderDate: result.reminderDate!,
        );
      } else {
        await notifier.cancelNoteReminder(result.id);
      }
    }
  }
}

class _NotesBody extends StatelessWidget {
  final List<NoteEntity> notes;

  const _NotesBody({required this.notes});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : (constraints.maxWidth >= 480 ? 2 : 1);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Text(
              'Sticky Notes',
              style: AppTypography.courseTitle(paper).copyWith(fontSize: 22),
            ),
            const SizedBox(height: 6),
            Text(
              'Quickly jot down important college updates, assignment deadlines, or reminders.',
              style: AppTypography.bodyMedium(muted),
            ),
            const SizedBox(height: 18),
            if (notes.isEmpty)
              GlassCard(
                child: Column(
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 16),
                    Text('No Notes Yet', style: AppTypography.cardTitle(paper)),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to create your first sticky note.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium(muted),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notes.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 1 ? 2.0 : 1.05,
                ),
                itemBuilder: (context, index) => NoteCard(note: notes[index]),
              ),
          ],
        );
      },
    );
  }
}
