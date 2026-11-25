import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../subjects/domain/entities/subject_entity.dart';
import '../../../timetable/domain/entities/timetable_session_entity.dart';
import '../../domain/entities/daily_task_entity.dart';
import '../providers/daily_flow_controller.dart';

/// DailyFlow timeline cards for tasks, scheduled classes, and metadata chips.
///
/// Ownership: DailyFlow Feature
// ==========================================
// DAILYFLOW - Timetable Session Block Card
// Read-only representation of a class session synced from weekly timetable.
// ==========================================
class DailyTimetableBlockCard extends StatelessWidget {
  final TimetableSessionEntity session;
  final SubjectEntity? subject;

  const DailyTimetableBlockCard({
    super.key,
    required this.session,
    this.subject,
  });

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

// ==========================================
// DAILYFLOW - Task Item Card
// Supports 1-tap completion, snooze/edit/delete menu, reminder pills, and subtasks.
// ==========================================
class DailyTaskCard extends ConsumerWidget {
  final DailyTaskEntity task;
  final SubjectEntity? subject;
  final bool hasConflict;
  final VoidCallback onEdit;

  const DailyTaskCard({
    super.key,
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
                            DailyBadgeChip(
                              label:
                                  '⏰ ${DateFormat('MMM d, h:mm a').format(task.reminderAt!)}',
                              color: AppColors.amber,
                            ),
                          if (task.startTime != null)
                            DailyBadgeChip(
                              label: task.startTime!,
                              color: muted,
                            ),
                          if (subject != null)
                            DailyBadgeChip(
                              label: subject!.name,
                              color: AppColors.inkGreen,
                            ),
                          if (hasConflict)
                            const DailyBadgeChip(
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

// ==========================================
// DAILYFLOW - Task Metadata Badge Chip
// ==========================================
class DailyBadgeChip extends StatelessWidget {
  final String label;
  final Color color;

  const DailyBadgeChip({super.key, required this.label, required this.color});

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
