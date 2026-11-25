import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../../timetable/domain/entities/timetable_session_entity.dart';
import '../../domain/entities/daily_task_entity.dart';
import '../../domain/services/daily_flow_planner_service.dart';
import '../providers/daily_flow_controller.dart';
import '../providers/daily_flow_providers.dart';
import '../widgets/daily_task_editor_dialog.dart';

/// Clean, simplified DailyFlow checklist & smart-reminder planner.
/// Morning briefing (07:00), evening review (22:00), and task reminders remain
/// synced automatically via [dailyFlowReminderSchedulerProvider] &
/// [dailyFlowRoutineSchedulerProvider].
class DailyFlowPage extends ConsumerWidget {
  final bool showBackButton;

  const DailyFlowPage({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(dailyFlowSelectedDateProvider);
    final statusFilter = ref.watch(dailyFlowStatusFilterProvider);
    final timeline = ref.watch(dailyFlowTimelineProvider);
    final summary = ref.watch(dailyFlowDaySummaryProvider);
    final subjects = ref.watch(subjectsStreamProvider).valueOrNull ?? const [];
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final tasks =
        ref.watch(dailyFlowTasksStreamProvider).valueOrNull ?? const [];
    final subjectById = {for (final s in subjects) s.id: s};

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Scaffold(
      backgroundColor: showBackButton ? null : Colors.transparent,
      appBar: showBackButton
          ? AppBar(
              title: const Text('DailyFlow'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
              actions: [
                IconButton(
                  tooltip: 'Jump to Today',
                  icon: const Icon(Icons.today_rounded),
                  onPressed: () {
                    ref.read(dailyFlowSelectedDateProvider.notifier).state =
                        DateTime.now();
                  },
                ),
              ],
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
        children: [
          // Compact Date Navigation + Done Summary
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous day',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    ref.read(dailyFlowSelectedDateProvider.notifier).state =
                        selectedDate.subtract(const Duration(days: 1));
                  },
                  icon: Icon(Icons.chevron_left_rounded, color: paper),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        ref.read(dailyFlowSelectedDateProvider.notifier).state =
                            picked;
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        children: [
                          Text(
                            _formatDayHeader(selectedDate),
                            style: AppTypography.cardTitle(paper),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            DateFormat('EEE, MMM d').format(selectedDate),
                            style: AppTypography.bodySmall(muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next day',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    ref.read(dailyFlowSelectedDateProvider.notifier).state =
                        selectedDate.add(const Duration(days: 1));
                  },
                  icon: Icon(Icons.chevron_right_rounded, color: paper),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Rolling 7-Day Planning Horizon Strip
          _HorizonStrip(
            selectedDate: selectedDate,
            horizonDays: settings?.dailyFlowPlanningHorizonDays ?? 7,
            tasks: tasks,
            onSelectDate: (d) =>
                ref.read(dailyFlowSelectedDateProvider.notifier).state = d,
          ),

          const SizedBox(height: 10),

          // Inline Quick-Add Bar
          _QuickAddTaskBar(
            selectedDate: selectedDate,
            onOpenDetailedEditor: (draftTitle) => _openEditor(
              context,
              ref,
              selectedDate,
              subjects,
              initialTitle: draftTitle,
            ),
          ),

          const SizedBox(height: 10),

          // Simple 3-chip filter + Smart Reminder status hint
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: statusFilter == null,
                        onSelected: (_) =>
                            ref
                                    .read(
                                      dailyFlowStatusFilterProvider.notifier,
                                    )
                                    .state =
                                null,
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Pending'),
                        selected: statusFilter == DailyTaskStatus.planned,
                        onSelected: (_) =>
                            ref
                                .read(dailyFlowStatusFilterProvider.notifier)
                                .state = DailyTaskStatus
                                .planned,
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Done'),
                        selected: statusFilter == DailyTaskStatus.completed,
                        onSelected: (_) =>
                            ref
                                .read(dailyFlowStatusFilterProvider.notifier)
                                .state = DailyTaskStatus
                                .completed,
                      ),
                    ],
                  ),
                ),
              ),
              if (summary.totalTasks > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inkGreenSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${summary.completedTasks}/${summary.totalTasks} done',
                    style: AppTypography.bodySmall(
                      AppColors.inkGreen,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              if (settings?.pushNotificationsEnabled == true &&
                  (settings?.dailyFlowSmartRemindersEnabled ?? true))
                Tooltip(
                  message:
                      'Smart reminders active (${settings?.dailyFlowMorningTime ?? "07:00"} briefing)',
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      size: 18,
                      color: AppColors.inkGreen,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Clean Task & Class List
          if (timeline.isEmpty)
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    'No classes or tasks planned',
                    style: AppTypography.cardTitle(paper),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type a task above and hit + to add it quickly, or tap the tune icon to set a reminder.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium(muted),
                  ),
                ],
              ),
            )
          else
            ...timeline.map((item) {
              return switch (item) {
                TimetableTimelineItem(:final session) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TimetableBlockCard(
                    session: session,
                    subject: subjectById[session.subjectId],
                  ),
                ),
                TaskTimelineItem(:final task, :final hasTimetableConflict) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DailyTaskCard(
                      task: task,
                      subject: task.subjectId != null
                          ? subjectById[task.subjectId]
                          : null,
                      hasConflict: hasTimetableConflict,
                      onEdit: () => _openEditor(
                        context,
                        ref,
                        selectedDate,
                        subjects,
                        existingTask: task,
                      ),
                    ),
                  ),
              };
            }),
        ],
      ),
    );
  }

  String _formatDayHeader(DateTime date) {
    final todayKey = AppDateUtils.todayStr();
    final key = AppDateUtils.formatDateKey(date);
    if (key == todayKey) return 'Today';
    final tomorrowKey = AppDateUtils.formatDateKey(
      DateTime.now().add(const Duration(days: 1)),
    );
    if (key == tomorrowKey) return 'Tomorrow';
    final yesterdayKey = AppDateUtils.formatDateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    if (key == yesterdayKey) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    DateTime initialDate,
    List<SubjectEntity> subjects, {
    DailyTaskEntity? existingTask,
    String? initialTitle,
  }) async {
    final result = await showDialog<DailyTaskEntity>(
      context: context,
      builder: (_) => DailyTaskEditorDialog(
        existingTask: existingTask,
        initialDate: initialDate,
        initialTitle: initialTitle,
        subjects: subjects,
      ),
    );
    if (result != null) {
      await ref.read(dailyFlowControllerProvider.notifier).saveTask(result);
    }
  }
}

class _QuickAddTaskBar extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<String?> onOpenDetailedEditor;

  const _QuickAddTaskBar({
    required this.selectedDate,
    required this.onOpenDetailedEditor,
  });

  @override
  ConsumerState<_QuickAddTaskBar> createState() => _QuickAddTaskBarState();
}

class _QuickAddTaskBarState extends ConsumerState<_QuickAddTaskBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitQuickTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    final task = DailyTaskEntity(
      id: 'df_${now.microsecondsSinceEpoch}',
      title: title,
      scheduledDate: AppDateUtils.formatDateKey(widget.selectedDate),
      createdAt: now,
      updatedAt: now,
    );
    _controller.clear();
    await ref.read(dailyFlowControllerProvider.notifier).saveTask(task);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: AppTypography.inputText(paper),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitQuickTask(),
              decoration: InputDecoration(
                hintText: 'Add a task...',
                hintStyle: AppTypography.inputHint(
                  muted.withValues(alpha: 0.85),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Add with reminder & options',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              final draft = _controller.text.trim();
              _controller.clear();
              widget.onOpenDetailedEditor(draft.isEmpty ? null : draft);
            },
            icon: Icon(
              Icons.notifications_none_rounded,
              color: muted,
              size: 20,
            ),
          ),
          const SizedBox(width: 2),
          IconButton.filled(
            tooltip: 'Quick add task',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.inkGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: _submitQuickTask,
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _TimetableBlockCard extends StatelessWidget {
  final TimetableSessionEntity session;
  final SubjectEntity? subject;

  const _TimetableBlockCard({required this.session, this.subject});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject?.name ?? session.label,
                  style: AppTypography.cardTitle(paper).copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Class • ${session.label}',
                  style: AppTypography.bodySmall(muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTaskCard extends ConsumerWidget {
  final DailyTaskEntity task;
  final SubjectEntity? subject;
  final bool hasConflict;
  final VoidCallback onEdit;

  const _DailyTaskCard({
    required this.task,
    this.subject,
    this.hasConflict = false,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final controller = ref.read(dailyFlowControllerProvider.notifier);
    final isCompleted = task.status == DailyTaskStatus.completed;

    return GlassCard(
      onTap: onEdit,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 1-tap Done Checkbox
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => isCompleted
                    ? controller.reopenTask(task)
                    : controller.completeTask(task),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 24,
                    color: isCompleted ? AppColors.inkGreen : muted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTypography.cardTitle(paper).copyWith(
                        fontSize: 15,
                        color: isCompleted ? muted : paper,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (task.reminderAt != null ||
                        task.startTime != null ||
                        subject != null ||
                        hasConflict) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (task.reminderAt != null &&
                              !task.status.isTerminal)
                            _BadgeChip(
                              label:
                                  '⏰ ${DateFormat('MMM d, h:mm a').format(task.reminderAt!)}',
                              color: AppColors.amber,
                            ),
                          if (task.startTime != null)
                            _BadgeChip(label: task.startTime!, color: muted),
                          if (subject != null)
                            _BadgeChip(
                              label: subject!.name,
                              color: AppColors.inkGreen,
                            ),
                          if (hasConflict)
                            const _BadgeChip(
                              label: 'Overlaps class',
                              color: AppColors.penRed,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: muted, size: 20),
                padding: EdgeInsets.zero,
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'snooze15':
                      await controller.snoozeReminder(
                        task,
                        const Duration(minutes: 15),
                      );
                    case 'snooze60':
                      await controller.snoozeReminder(
                        task,
                        const Duration(hours: 1),
                      );
                    case 'reopen':
                      await controller.reopenTask(task);
                    case 'delete':
                      await controller.deleteTask(task.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit / Reminder'),
                  ),
                  if (!task.status.isTerminal) ...[
                    const PopupMenuItem(
                      value: 'snooze15',
                      child: Text('Snooze Reminder +15m'),
                    ),
                    const PopupMenuItem(
                      value: 'snooze60',
                      child: Text('Snooze Reminder +1h'),
                    ),
                  ] else
                    const PopupMenuItem(
                      value: 'reopen',
                      child: Text('Reopen Task'),
                    ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          if (task.notes.trim().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4),
              child: Text(
                task.notes,
                style: AppTypography.bodySmall(muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (task.subtasks.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...task.subtasks.map(
              (st) => InkWell(
                onTap: () => controller.toggleSubtask(task, st.id),
                child: Padding(
                  padding: const EdgeInsets.only(left: 36, top: 2, bottom: 2),
                  child: Row(
                    children: [
                      Icon(
                        st.isDone
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 16,
                        color: st.isDone ? AppColors.inkGreen : muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          st.title,
                          style: AppTypography.bodySmall(paper).copyWith(
                            decoration: st.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall(
          color,
        ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HorizonStrip extends StatelessWidget {
  final DateTime selectedDate;
  final int horizonDays;
  final List<DailyTaskEntity> tasks;
  final ValueChanged<DateTime> onSelectDate;

  const _HorizonStrip({
    required this.selectedDate,
    required this.horizonDays,
    required this.tasks,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedKey = AppDateUtils.formatDateKey(selectedDate);
    final count = horizonDays.clamp(1, 14);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final day = today.add(Duration(days: index));
          final key = AppDateUtils.formatDateKey(day);
          final isSelected = key == selectedKey;
          final pendingCount = tasks
              .where(
                (t) =>
                    !t.isDeleted &&
                    !t.status.isTerminal &&
                    t.scheduledDate == key,
              )
              .length;
          final label = index == 0
              ? 'Today'
              : (index == 1 ? 'Tomorrow' : DateFormat('EEE d').format(day));

          return ChoiceChip(
            label: Text(pendingCount > 0 ? '$label ($pendingCount)' : label),
            selected: isSelected,
            onSelected: (_) => onSelectDate(day),
          );
        },
      ),
    );
  }
}
