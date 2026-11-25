import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../domain/entities/daily_task_entity.dart';

/// Modal dialog for creating or editing a [DailyTaskEntity] with time block,
/// priority, recurrence, linked subject, reminder scheduling, and subtasks.
class DailyTaskEditorDialog extends StatefulWidget {
  final DailyTaskEntity? existingTask;
  final DateTime initialDate;
  final List<SubjectEntity> subjects;

  const DailyTaskEditorDialog({
    super.key,
    this.existingTask,
    required this.initialDate,
    this.subjects = const [],
  });

  @override
  State<DailyTaskEditorDialog> createState() => _DailyTaskEditorDialogState();
}

class _DailyTaskEditorDialogState extends State<DailyTaskEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _subtaskController;

  late DateTime _scheduledDate;
  TimeOfDay? _startTime;
  late int _estimatedMinutes;
  late DailyTaskPriority _priority;
  late DailyTaskRecurrence _recurrence;
  String? _selectedSubjectId;
  DateTime? _reminderAt;
  late List<DailySubtaskEntity> _subtasks;
  String? _errorText;

  static const _durationPresets = [15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleController = TextEditingController(text: t?.title ?? '');
    _notesController = TextEditingController(text: t?.notes ?? '');
    _subtaskController = TextEditingController();

    _scheduledDate = t != null
        ? (DateTime.tryParse(t.scheduledDate) ?? widget.initialDate)
        : widget.initialDate;

    if (t?.startTime != null && t!.startTime!.contains(':')) {
      final parts = t.startTime!.split(':');
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        _startTime = TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
      }
    }

    _estimatedMinutes = t?.estimatedMinutes ?? 30;
    _priority = t?.priority ?? DailyTaskPriority.medium;
    _recurrence = t?.recurrence ?? DailyTaskRecurrence.none;
    _selectedSubjectId = t?.subjectId;
    _reminderAt = t?.reminderAt;
    _subtasks = List<DailySubtaskEntity>.from(t?.subtasks ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _subtaskController.dispose();
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

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickCustomReminder() async {
    final now = DateTime.now();
    final initial = _reminderAt != null && _reminderAt!.isAfter(now)
        ? _reminderAt!
        : now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
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

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(
        DailySubtaskEntity(
          id: 'st_${DateTime.now().microsecondsSinceEpoch}',
          title: text,
        ),
      );
      _subtaskController.clear();
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
    final formattedStart = _startTime != null
        ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final task = DailyTaskEntity(
      id: existing?.id ?? 'df_${now.microsecondsSinceEpoch}',
      title: title,
      notes: _notesController.text.trim(),
      status: existing?.status ?? DailyTaskStatus.planned,
      priority: _priority,
      recurrence: _recurrence,
      scheduledDate: AppDateUtils.formatDateKey(_scheduledDate),
      startTime: formattedStart,
      estimatedMinutes: _estimatedMinutes,
      elapsedSeconds: existing?.elapsedSeconds ?? 0,
      activeStartedAt: existing?.activeStartedAt,
      reminderAt: _reminderAt,
      subjectId: _selectedSubjectId,
      timetableSessionId: existing?.timetableSessionId,
      subtasks: _subtasks,
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
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 680),
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
                    widget.existingTask == null ? 'Plan Task' : 'Edit Task',
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
                label: 'Task Title',
                hintText: 'e.g., Complete OS Lab Assignment',
                errorText: _errorText,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hintText: 'Key steps, links, or deliverables...',
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              // Date & Start Time row
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
                    onPressed: _pickStartTime,
                    icon: const Icon(Icons.schedule_rounded, size: 15),
                    label: Text(
                      _startTime != null
                          ? _startTime!.format(context)
                          : 'Set Start Time',
                    ),
                  ),
                  if (_startTime != null)
                    IconButton(
                      tooltip: 'Clear start time',
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _startTime = null),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Estimated Duration
              Text('Estimated Focus', style: AppTypography.inputLabel(muted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _durationPresets.map((mins) {
                  final selected = _estimatedMinutes == mins;
                  return ChoiceChip(
                    label: Text('${mins}m'),
                    selected: selected,
                    onSelected: (_) => setState(() => _estimatedMinutes = mins),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Priority
              Text('Priority', style: AppTypography.inputLabel(muted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: DailyTaskPriority.values.map((p) {
                  return ChoiceChip(
                    label: Text(p.label),
                    selected: _priority == p,
                    onSelected: (_) => setState(() => _priority = p),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Recurrence
              Text('Repeat', style: AppTypography.inputLabel(muted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: DailyTaskRecurrence.values.map((r) {
                  return ChoiceChip(
                    label: Text(r.label),
                    selected: _recurrence == r,
                    onSelected: (_) => setState(() => _recurrence = r),
                  );
                }).toList(),
              ),

              if (activeSubjects.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Link Subject (Optional)',
                  style: AppTypography.inputLabel(muted),
                ),
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
                  onChanged: (val) => setState(() => _selectedSubjectId = val),
                ),
              ],

              const SizedBox(height: 14),
              // Reminder section
              Text(
                'Reminder Notification',
                style: AppTypography.inputLabel(muted),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('In 15m'),
                    onPressed: () => setState(
                      () => _reminderAt = DateTime.now().add(
                        const Duration(minutes: 15),
                      ),
                    ),
                  ),
                  ActionChip(
                    label: const Text('In 1h'),
                    onPressed: () => setState(
                      () => _reminderAt = DateTime.now().add(
                        const Duration(hours: 1),
                      ),
                    ),
                  ),
                  ActionChip(
                    label: const Text('Pick Date & Time'),
                    onPressed: _pickCustomReminder,
                  ),
                  if (_reminderAt != null)
                    ActionChip(
                      label: const Text('Clear'),
                      onPressed: () => setState(() => _reminderAt = null),
                    ),
                ],
              ),
              if (_reminderAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  '⏰ Scheduled: ${DateFormat('MMM d, h:mm a').format(_reminderAt!)}',
                  style: AppTypography.bodySmall(AppColors.amber),
                ),
              ],

              const SizedBox(height: 14),
              // Subtasks
              Text('Subtasks', style: AppTypography.inputLabel(muted)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _subtaskController,
                      hintText: 'Add checklist step...',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addSubtask,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              if (_subtasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._subtasks.map(
                  (st) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      st.isDone
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 18,
                      color: st.isDone ? AppColors.inkGreen : muted,
                    ),
                    title: Text(
                      st.title,
                      style: AppTypography.bodyMedium(paper),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () => setState(
                        () => _subtasks.removeWhere((e) => e.id == st.id),
                      ),
                    ),
                  ),
                ),
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
                      label: widget.existingTask == null
                          ? 'Create Task'
                          : 'Save',
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
