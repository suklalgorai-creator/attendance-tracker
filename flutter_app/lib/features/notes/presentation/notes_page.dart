import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../domain/entities/note_entity.dart';

/// Sticky Notes CRUD screen matching React `NotesPage.jsx`.
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
        onPressed: () => _openEditor(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    NoteEntity? note,
  }) async {
    final result = await showDialog<NoteEntity>(
      context: context,
      builder: (_) => _NoteEditorDialog(note: note),
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
                itemBuilder: (context, index) => _NoteCard(note: notes[index]),
              ),
          ],
        );
      },
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final NoteEntity note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final noteColor = _parseNoteColor(note.color, isDark);

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
      builder: (_) => _NoteEditorDialog(note: note),
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

class _NoteEditorDialog extends StatefulWidget {
  final NoteEntity? note;

  const _NoteEditorDialog({this.note});

  @override
  State<_NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<_NoteEditorDialog> {
  late final TextEditingController _contentController;
  late String _color;
  DateTime? _reminderDate;

  static const _colors = <String>[
    '#2610B981',
    '#26F59E0B',
    '#26F43F5E',
    '#263B82F6',
    '#26A78BFA',
  ];

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _color = widget.note?.color ?? _colors.first;
    _reminderDate = widget.note?.reminderDate;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _reminderDate != null && !_reminderDate!.isBefore(today)
        ? _reminderDate!
        : now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !mounted) return;

    final initialTime = _reminderDate != null
        ? TimeOfDay.fromDateTime(_reminderDate!)
        : TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (!mounted) return;

    final effectiveTime = pickedTime ?? initialTime;
    setState(() {
      _reminderDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        effectiveTime.hour,
        effectiveTime.minute,
      );
    });
  }

  void _save() {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    final now = DateTime.now();
    Navigator.of(context).pop(
      NoteEntity(
        id: widget.note?.id ?? now.microsecondsSinceEpoch.toString(),
        content: content,
        color: _color,
        reminderDate: _reminderDate,
        createdAt: widget.note?.createdAt ?? now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              autofocus: true,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Jot something down...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Note color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final color in _colors)
                  GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: _parseNoteColor(
                        color,
                        Theme.of(context).brightness == Brightness.dark,
                      ),
                      child: _color == color
                          ? const Icon(Icons.check, size: 16)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _reminderDate == null
                        ? 'No reminder set'
                        : DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(_reminderDate!.toLocal()),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickReminder,
                  icon: const Icon(Icons.alarm_add_rounded),
                  label: const Text('Reminder'),
                ),
                if (_reminderDate != null)
                  IconButton(
                    tooltip: 'Clear reminder',
                    onPressed: () => setState(() => _reminderDate = null),
                    icon: const Icon(Icons.clear_rounded),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Save note',
          variant: AppButtonVariant.present,
          onPressed: _save,
        ),
      ],
    );
  }
}

Color _parseNoteColor(String value, bool isDark) {
  if (value.startsWith('#')) {
    final hex = value.substring(1);
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed != null) {
      return hex.length == 6 ? Color(0xFF000000 | parsed) : Color(parsed);
    }
  }
  return isDark ? AppColors.surfaceHoverDark : AppColors.surfaceLight;
}
