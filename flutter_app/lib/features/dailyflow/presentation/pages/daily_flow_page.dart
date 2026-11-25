import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../domain/entities/daily_task_entity.dart';
import '../../domain/services/daily_flow_planner_service.dart';
import '../providers/daily_flow_controller.dart';
import '../providers/daily_flow_providers.dart';
import '../widgets/daily_flow_date_header.dart';
import '../widgets/daily_flow_quick_add_bar.dart';
import '../widgets/daily_task_card.dart';
import '../widgets/daily_task_editor_dialog.dart';

/// Main DailyFlow screen coordinating date selection, rolling horizon strip,
/// inline task capture, status filters, and smart-reminder timeline cards.
///
/// Morning briefing (07:00), evening review (22:00), and task reminders remain
/// synced automatically via [dailyFlowReminderSchedulerProvider] &
/// [dailyFlowRoutineSchedulerProvider].
///
/// Ownership: DailyFlow Feature
// ==========================================
// DAILYFLOW - Main Planner Page
// ==========================================
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
          // Date Navigation Card
          DailyFlowDateHeader(
            selectedDate: selectedDate,
            onDateSelected: (d) =>
                ref.read(dailyFlowSelectedDateProvider.notifier).state = d,
          ),

          const SizedBox(height: 10),

          // Rolling 7-Day Planning Horizon Strip
          DailyFlowHorizonStrip(
            selectedDate: selectedDate,
            horizonDays: settings?.dailyFlowPlanningHorizonDays ?? 7,
            tasks: tasks,
            onSelectDate: (d) =>
                ref.read(dailyFlowSelectedDateProvider.notifier).state = d,
          ),

          const SizedBox(height: 10),

          // Inline Quick-Add Task Bar
          DailyFlowQuickAddBar(
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

          // Filter Chips, Completion Pill & Smart-Reminder Indicator
          _DailyFlowFilterBar(
            statusFilter: statusFilter,
            summary: summary,
            smartRemindersActive:
                settings?.pushNotificationsEnabled == true &&
                (settings?.dailyFlowSmartRemindersEnabled ?? true),
            morningTime: settings?.dailyFlowMorningTime ?? '07:00',
            onFilterChanged: (status) =>
                ref.read(dailyFlowStatusFilterProvider.notifier).state = status,
          ),

          const SizedBox(height: 10),

          // Task & Scheduled Class Timeline
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
                  child: DailyTimetableBlockCard(
                    session: session,
                    subject: subjectById[session.subjectId],
                  ),
                ),
                TaskTimelineItem(:final task, :final hasTimetableConflict) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DailyTaskCard(
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

// ==========================================
// DAILYFLOW - Status Filter & Progress Row
// ==========================================
class _DailyFlowFilterBar extends StatelessWidget {
  final DailyTaskStatus? statusFilter;
  final DailyFlowDaySummary summary;
  final bool smartRemindersActive;
  final String morningTime;
  final ValueChanged<DailyTaskStatus?> onFilterChanged;

  const _DailyFlowFilterBar({
    required this.statusFilter,
    required this.summary,
    required this.smartRemindersActive,
    required this.morningTime,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: statusFilter == null,
                  onSelected: (_) => onFilterChanged(null),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Pending'),
                  selected: statusFilter == DailyTaskStatus.planned,
                  onSelected: (_) => onFilterChanged(DailyTaskStatus.planned),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Done'),
                  selected: statusFilter == DailyTaskStatus.completed,
                  onSelected: (_) => onFilterChanged(DailyTaskStatus.completed),
                ),
              ],
            ),
          ),
        ),
        if (summary.totalTasks > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        if (smartRemindersActive)
          Tooltip(
            message: 'Smart reminders active ($morningTime briefing)',
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
    );
  }
}
