import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../domain/entities/daily_task_entity.dart';

/// Clean modal dialog for creating or editing a DailyFlow task with date,
/// optional OS reminder notification, notes, and optional subject link.
///
/// Ownership: DailyFlow Feature (Task Editor)
// ==========================================
// DAILYFLOW DIALOG - Task & Reminder Editor
// ==========================================
class DailyTaskEditorDialog extends StatefulWidget {
  final DailyTaskEntity? existingTask;
  final DateTime initialDate;
  final String? initialTitle;
  final List<SubjectEntity> subjects;

  const DailyTaskEditorDialog({
    super.key,
    this.existingTask,
    required this.initialDate,
    this.initialTitle,
    this.subjects = const [],
  });

  @override
  State<DailyTaskEditorDialog> createState() => _DailyTaskEditorDialogState();
}

class _DailyTaskEditorDialogState extends State<DailyTaskEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  late DateTime _scheduledDate;
  String? _selectedSubjectId;
  DateTime? _reminderAt;
  bool _showDetails = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleController = TextEditingController(
      text: t?.title ?? widget.initialTitle ?? '',
    );
    _notesController = TextEditingController(text: t?.notes ?? '');

    _scheduledDate = t != null
        ? (DateTime.tryParse(t.scheduledDate) ?? widget.initialDate)
        : widget.initialDate;

    _selectedSubjectId = t?.subjectId;
    _reminderAt = t?.reminderAt;
    _showDetails =
        t != null && (t.notes.trim().isNotEmpty || t.subjectId != null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickScheduledDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickCustomReminder() async {
    final now = DateTime.now();
    final initial = _reminderAt ?? _scheduledDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderAt != null
          ? TimeOfDay.fromDateTime(_reminderAt!)
          : TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;
    setState(() {
      _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = 'Task title is required');
      return;
    }

    final now = DateTime.now();
    final existing = widget.existingTask;

    final task = DailyTaskEntity(
      id: existing?.id ?? 'df_${now.microsecondsSinceEpoch}',
      title: title,
      notes: _notesController.text.trim(),
      status: existing?.status ?? DailyTaskStatus.planned,
      priority: existing?.priority ?? DailyTaskPriority.medium,
      recurrence: existing?.recurrence ?? DailyTaskRecurrence.none,
      scheduledDate: AppDateUtils.formatDateKey(_scheduledDate),
      startTime: existing?.startTime,
      estimatedMinutes: existing?.estimatedMinutes ?? 30,
      elapsedSeconds: existing?.elapsedSeconds ?? 0,
      activeStartedAt: existing?.activeStartedAt,
      reminderAt: _reminderAt,
      subjectId: _selectedSubjectId,
      timetableSessionId: existing?.timetableSessionId,
      subtasks: existing?.subtasks ?? const [],
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      completedAt: existing?.completedAt,
      isDeleted: false,
    );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surface = isDark
        ? AppColors.surfaceSolidDark
        : AppColors.surfaceSolidLight;
    final activeSubjects = widget.subjects.where((s) => !s.isDeleted).toList();

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingTask == null ? 'New Task' : 'Edit Task',
                    style: AppTypography.cardTitle(
                      paper,
                    ).copyWith(fontSize: 18),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _titleController,
                label: 'Task',
                hintText: 'e.g., Revise Operating Systems',
                errorText: _errorText,
              ),
              const SizedBox(height: 14),

              // Date & Reminder buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickScheduledDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 15),
                    label: Text(DateFormat('MMM d, y').format(_scheduledDate)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickCustomReminder,
                    icon: Icon(
                      _reminderAt != null
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      size: 16,
                      color: _reminderAt != null ? AppColors.amber : null,
                    ),
                    label: Text(
                      _reminderAt != null
                          ? DateFormat('MMM d, h:mm a').format(_reminderAt!)
                          : 'Set Reminder',
                    ),
                  ),
                  if (_reminderAt != null)
                    IconButton(
                      tooltip: 'Clear reminder',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _reminderAt = null),
                    ),
                ],
              ),

              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _showDetails = !_showDetails),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        _showDetails
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _showDetails
                              ? 'Hide notes & subject'
                              : 'Add notes or subject (optional)',
                          style: AppTypography.bodySmall(muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_showDetails) ...[
                const SizedBox(height: 10),
                AppTextField(
                  controller: _notesController,
                  label: 'Notes',
                  hintText: 'Optional details...',
                  maxLines: 2,
                ),
                if (activeSubjects.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Subject', style: AppTypography.inputLabel(muted)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedSubjectId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...activeSubjects.map(
                        (s) => DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedSubjectId = val),
                  ),
                ],
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.ghost,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: widget.existingTask == null ? 'Add Task' : 'Save',
                      variant: AppButtonVariant.present,
                      onPressed: _submit,
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
}
