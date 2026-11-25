import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../providers/daily_flow_controller.dart';
import '../providers/daily_flow_providers.dart';

/// Compact Dashboard card surfacing today's DailyFlow execution state,
/// quick start/complete actions, and navigation into DailyFlow.
class DailyFlowDashboardCard extends ConsumerWidget {
  const DailyFlowDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(todaysDailyFlowSummaryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final focusTask = summary.activeTask ?? summary.recommendedNextTask;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.go('/dailyflow'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'DailyFlow',
                  style: AppTypography.cardTitle(paper),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${summary.completedTasks}/${summary.totalTasks} done',
                style: AppTypography.bodySmall(
                  AppColors.inkGreen,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 18, color: muted),
            ],
          ),
          const SizedBox(height: 8),
          if (focusTask != null) ...[
            Text(
              summary.activeTask != null
                  ? 'Running: ${focusTask.title}'
                  : 'Next: ${focusTask.title}',
              style: AppTypography.bodyLarge(paper),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (summary.smartFocusReason != null && summary.activeTask == null)
              Text(
                summary.smartFocusReason!,
                style: AppTypography.bodySmall(muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Mark Done',
                    icon: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    variant: AppButtonVariant.present,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    fontSize: 12.5,
                    onPressed: () => ref
                        .read(dailyFlowControllerProvider.notifier)
                        .completeTask(focusTask),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Open',
                    variant: AppButtonVariant.ghost,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    fontSize: 12.5,
                    onPressed: () => context.go('/dailyflow'),
                  ),
                ),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.totalTasks == 0
                        ? 'Quickly add tasks & smart reminders for today.'
                        : 'All planned tasks completed for today!',
                    style: AppTypography.bodyMedium(muted),
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'Plan',
                  variant: AppButtonVariant.ghost,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  fontSize: 12.5,
                  onPressed: () => context.go('/dailyflow'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
