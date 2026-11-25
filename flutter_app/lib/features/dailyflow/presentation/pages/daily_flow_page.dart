import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../../timetable/domain/entities/timetable_session_entity.dart';
import '../../domain/entities/daily_task_entity.dart';
import '../../domain/services/daily_flow_planner_service.dart';
import '../providers/daily_flow_controller.dart';
import '../providers/daily_flow_providers.dart';
import '../widgets/daily_task_editor_dialog.dart';

/// Production DailyFlow Planning, Reminder & Execution screen.
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, selectedDate, subjects),
        backgroundColor: AppColors.inkGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 96),
        children: [
          // Date Navigation Header
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous day',
                  onPressed: () {
                    ref.read(dailyFlowSelectedDateProvider.notifier).state =
                        selectedDate.subtract(const Duration(days: 1));
                  },
                  icon: Icon(Icons.chevron_left_rounded, color: paper),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        ref
                            .read(dailyFlowSelectedDateProvider.notifier)
                            .state = picked;
                      }
                    },
                    child: Column(
                      children: [
                        Text(
                          _formatDayHeader(selectedDate),
                          style: AppTypography.cardTitle(paper),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('EEEE, MMM d, y').format(selectedDate),
                          style: AppTypography.bodySmall(muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next day',
                  onPressed: () {
                    ref.read(dailyFlowSelectedDateProvider.notifier).state =
                        selectedDate.add(const Duration(days: 1));
                  },
                  icon: Icon(Icons.chevron_right_rounded, color: paper),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Active Focus Execution Banner or Smart Next Recommendation
          if (summary.activeTask != null) ...[
            _LiveFocusCard(task: summary.activeTask!),
            const SizedBox(height: 12),
          ] else if (summary.recommendedNextTask != null) ...[
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUGGESTED NEXT FOCUS',
                          style: AppTypography.eyebrow(AppColors.amber),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary.recommendedNextTask!.title,
                          style: AppTypography.cardTitle(paper),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (summary.smartFocusReason != null)
                          Text(
                            summary.smartFocusReason!,
                            style: AppTypography.bodySmall(muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: 'Start',
                    icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    fontSize: 12.5,
                    onPressed: () => ref
                        .read(dailyFlowControllerProvider.notifier)
                        .startTask(summary.recommendedNextTask!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Execution Progress Summary
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Execution Progress',
                        style: AppTypography.cardTitle(paper),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${summary.completedTasks}/${summary.totalTasks} done',
                      style: AppTypography.statLabel(AppColors.inkGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: summary.completionRate,
                    minHeight: 7,
                    backgroundColor: isDark
                        ? AppColors.ruleBrightDark
                        : AppColors.ruleBrightLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.inkGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Planned: ${summary.plannedMinutes}m',
                      style: AppTypography.bodySmall(muted),
                    ),
                    Text(
                      'Focused: ${(summary.executedSeconds / 60).floor()}m',
                      style: AppTypography.bodySmall(muted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: statusFilter == null,
                  onSelected: (_) =>
                      ref.read(dailyFlowStatusFilterProvider.notifier).state =
                          null,
                ),
                const SizedBox(width: 6),
                ...[
                  DailyTaskStatus.planned,
                  DailyTaskStatus.inProgress,
                  DailyTaskStatus.paused,
                  DailyTaskStatus.completed,
                  DailyTaskStatus.skipped,
                ].map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(status.label),
                      selected: statusFilter == status,
                      onSelected: (_) =>
                          ref
                                  .read(dailyFlowStatusFilterProvider.notifier)
                                  .state =
                              status,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Unified Timeline
          if (timeline.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('🗓️', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 10),
                  Text(
                    'No classes or tasks planned',
                    style: AppTypography.cardTitle(paper),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap "+ New Task" to time-block your study goals, assignments, and reminders.',
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
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TimetableBlockCard(
                    session: session,
                    subject: subjectById[session.subjectId],
                  ),
                ),
                TaskTimelineItem(
                  :final task,
                  :final hasTimetableConflict,
                ) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
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
  }) async {
    final result = await showDialog<DailyTaskEntity>(
      context: context,
      builder: (_) => DailyTaskEditorDialog(
        existingTask: existingTask,
        initialDate: initialDate,
        subjects: subjects,
      ),
    );
    if (result != null) {
      await ref.read(dailyFlowControllerProvider.notifier).saveTask(result);
    }
  }
}

class _LiveFocusCard extends ConsumerStatefulWidget {
  final DailyTaskEntity task;

  const _LiveFocusCard({required this.task});

  @override
  ConsumerState<_LiveFocusCard> createState() => _LiveFocusCardState();
}

class _LiveFocusCardState extends ConsumerState<_LiveFocusCard> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final elapsed = widget.task.totalElapsedSecondsAt(_now);
    final mins = (elapsed ~/ 60).toString().padLeft(2, '0');
    final secs = (elapsed % 60).toString().padLeft(2, '0');

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.inkGreenSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'ACTIVE FOCUS',
                    style: AppTypography.eyebrow(AppColors.inkGreen),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$mins:$secs / ${widget.task.estimatedMinutes}m',
                    style: AppTypography.statValue(
                      AppColors.inkGreen,
                    ).copyWith(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.task.title,
            style: AppTypography.cardTitle(paper),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Pause',
                  icon: Icon(Icons.pause_rounded, size: 16, color: paper),
                  variant: AppButtonVariant.ghost,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  fontSize: 12.5,
                  onPressed: () => ref
                      .read(dailyFlowControllerProvider.notifier)
                      .pauseTask(widget.task),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Complete',
                  icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  variant: AppButtonVariant.present,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  fontSize: 12.5,
                  onPressed: () => ref
                      .read(dailyFlowControllerProvider.notifier)
                      .completeTask(widget.task),
                ),
              ),
            ],
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
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.blueMesh.withValues(alpha: 0.9),
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
                  'Scheduled Class • ${session.label}',
                  style: AppTypography.bodySmall(muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blueMesh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Timetable',
              style: AppTypography.bodySmall(
                isDark ? AppColors.paperDark : AppColors.paperLight,
              ),
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

    final priorityColor = switch (task.priority) {
      DailyTaskPriority.urgent => AppColors.penRed,
      DailyTaskPriority.high => AppColors.amber,
      DailyTaskPriority.medium => AppColors.inkGreen,
      DailyTaskPriority.low => muted,
    };

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTypography.cardTitle(paper).copyWith(
                        decoration: task.status == DailyTaskStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _BadgeChip(
                          label: task.priority.label,
                          color: priorityColor,
                        ),
                        _BadgeChip(
                          label: task.status.label,
                          color: task.status == DailyTaskStatus.completed
                              ? AppColors.inkGreen
                              : muted,
                        ),
                        if (task.startTime != null)
                          _BadgeChip(
                            label: '${task.startTime} (${task.estimatedMinutes}m)',
                            color: muted,
                          )
                        else
                          _BadgeChip(
                            label: '${task.estimatedMinutes}m',
                            color: muted,
                          ),
                        if (subject != null)
                          _BadgeChip(label: subject!.name, color: AppColors.inkGreen),
                        if (hasConflict)
                          const _BadgeChip(
                            label: 'Overlaps class',
                            color: AppColors.penRed,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: muted, size: 20),
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
                    case 'skip':
                      await controller.skipTask(task);
                    case 'reopen':
                      await controller.reopenTask(task);
                    case 'delete':
                      await controller.deleteTask(task.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (!task.status.isTerminal) ...[
                    const PopupMenuItem(
                      value: 'snooze15',
                      child: Text('Snooze Reminder +15m'),
                    ),
                    const PopupMenuItem(
                      value: 'snooze60',
                      child: Text('Snooze Reminder +1h'),
                    ),
                    const PopupMenuItem(value: 'skip', child: Text('Skip')),
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
            const SizedBox(height: 8),
            Text(task.notes, style: AppTypography.bodyMedium(muted)),
          ],
          if (task.reminderAt != null && !task.status.isTerminal) ...[
            const SizedBox(height: 6),
            Text(
              '⏰ ${DateFormat('MMM d, h:mm a').format(task.reminderAt!)}',
              style: AppTypography.bodySmall(AppColors.amber),
            ),
          ],
          if (task.subtasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...task.subtasks.map(
              (st) => InkWell(
                onTap: () => controller.toggleSubtask(task, st.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        st.isDone
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 18,
                        color: st.isDone ? AppColors.inkGreen : muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          st.title,
                          style: AppTypography.bodyMedium(paper).copyWith(
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
          if (!task.status.isTerminal) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (task.status == DailyTaskStatus.inProgress)
                  Expanded(
                    child: AppButton(
                      label: 'Pause',
                      icon: Icon(Icons.pause_rounded, size: 16, color: paper),
                      variant: AppButtonVariant.ghost,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      fontSize: 12.5,
                      onPressed: () => controller.pauseTask(task),
                    ),
                  )
                else
                  Expanded(
                    child: AppButton(
                      label: task.status == DailyTaskStatus.paused
                          ? 'Resume'
                          : 'Start',
                      icon: Icon(Icons.play_arrow_rounded, size: 16, color: paper),
                      variant: AppButtonVariant.ghost,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      fontSize: 12.5,
                      onPressed: () => controller.startTask(task),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Complete',
                    icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    variant: AppButtonVariant.present,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    fontSize: 12.5,
                    onPressed: () => controller.completeTask(task),
                  ),
                ),
              ],
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
        style: AppTypography.bodySmall(color).copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
