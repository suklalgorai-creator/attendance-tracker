import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/notification_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/color_utils.dart';
import '../../domain/entities/note_entity.dart';
import 'note_editor_dialog.dart';

/// Sticky note grid tile rendering Markdown content preview, reminder stamp,
/// tap-to-edit modal trigger, and delete confirmation.
///
/// Ownership: Notes Feature
// ==========================================
// NOTES - Sticky Note Card
// ==========================================
class NoteCard extends ConsumerWidget {
  final NoteEntity note;

  const NoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final noteColor = parseHexColor(
      note.color,
      fallback: isDark ? AppColors.surfaceHoverDark : AppColors.surfaceLight,
    );

    return Material(
      color: noteColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editNote(context, ref, note),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: paper.withValues(alpha: .10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MarkdownPreview(content: note.content, color: paper),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (note.reminderDate != null)
                    Expanded(
                      child: Text(
                        '\u{23F0} ${DateFormat('dd MMM, hh:mm a').format(note.reminderDate!.toLocal())}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall(muted),
                      ),
                    )
                  else
                    const Spacer(),
                  IconButton(
                    tooltip: 'Delete note',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _deleteNote(context, ref),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref,
    NoteEntity note,
  ) async {
    final result = await showDialog<NoteEntity>(
      context: context,
      builder: (_) => NoteEditorDialog(note: note),
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

  Future<void> _deleteNote(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => dialogContext.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(notesRepositoryProvider).deleteNote(note.id);
      await ref.read(notificationServiceProvider).cancelNoteReminder(note.id);
    }
  }
}

class _MarkdownPreview extends StatelessWidget {
  final String content;
  final Color color;

  const _MarkdownPreview({required this.content, required this.color});

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTypography.bodyLarge(color);
    return ClipRect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: MarkdownBody(
          data: content,
          shrinkWrap: true,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: baseStyle,
            h1: baseStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
            h2: baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
            h3: baseStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            listBullet: baseStyle,
            strong: baseStyle.copyWith(fontWeight: FontWeight.w800),
            em: baseStyle.copyWith(fontStyle: FontStyle.italic),
            code: baseStyle.copyWith(
              fontFamily: 'monospace',
              fontSize: 13,
              backgroundColor: color.withValues(alpha: .08),
            ),
          ),
        ),
      ),
    );
  }
}
