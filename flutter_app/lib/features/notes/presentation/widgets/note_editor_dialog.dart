import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/note_entity.dart';

/// Modal dialog for creating or editing a sticky note with color tint and
/// optional reminder notification date/time.
///
/// Ownership: Notes Feature
// ==========================================
// NOTES - Note Editor Dialog
// ==========================================
class NoteEditorDialog extends StatefulWidget {
  final NoteEntity? note;

  const NoteEditorDialog({super.key, this.note});

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackTint = isDark
        ? AppColors.surfaceHoverDark
        : AppColors.surfaceLight;

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
                      backgroundColor: parseHexColor(
                        color,
                        fallback: fallbackTint,
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
