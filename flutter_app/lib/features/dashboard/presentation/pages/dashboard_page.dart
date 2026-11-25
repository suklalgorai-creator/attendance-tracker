import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/undo_snack_bar.dart';
import '../../../calendar/presentation/widgets/activity_card.dart';
import '../../../dailyflow/presentation/widgets/daily_flow_dashboard_card.dart';
import '../../../subjects/presentation/widgets/subject_dialog.dart';
import '../../domain/models/dashboard_stats.dart';
import '../providers/dashboard_controller.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/empty_dashboard_view.dart';
import '../widgets/overview_card.dart';
import '../widgets/quick_action_subject_card.dart';
import '../widgets/todays_schedule_card.dart';

/// Main Dashboard Page displaying today's DailyFlow summary, attendance overview,
/// and quick action subject cards.
///
/// Ownership: Dashboard Feature (UI Page)
// ==========================================
// DASHBOARD - Main Overview Screen
// ==========================================
class DashboardPage extends ConsumerWidget {
  final VoidCallback? onAddSubject;

  const DashboardPage({super.key, this.onAddSubject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final subjectStatsAsync = ref.watch(subjectStatsListProvider);

    final stats = statsAsync.valueOrNull ?? DashboardStats.empty();
    final subjectStatsList = subjectStatsAsync.valueOrNull ?? const [];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      children: [
        // DailyFlow Planning & Execution Summary Card
        const DailyFlowDashboardCard(),

        const SizedBox(height: 12),

        // Today's Scheduled Sessions Card (Conditional)
        const TodaysScheduleCard(),

        // Overview Hero Card
        OverviewCard(stats: stats),

        const SizedBox(height: 12),

        // Activity Card (Calendar View & Contribution Heatmap)
        const ActivityCard(),

        const SizedBox(height: 18),

        // Section Title: Quick Attendance
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Quick Attendance',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: paperColor,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subjectStatsList.isNotEmpty) ...[
                  Text(
                    '${subjectStatsList.length} ${subjectStatsList.length == 1 ? 'subject' : 'subjects'}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  key: const Key('add_subject_button'),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  color: AppColors.inkGreen,
                  tooltip: 'Add Subject',
                  visualDensity: VisualDensity.compact,
                  onPressed: onAddSubject ?? () => showSubjectDialog(context),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Subject Cards or Empty State Placeholder
        if (subjectStatsList.isEmpty)
          EmptyDashboardView(
            onAddSubject: onAddSubject ?? () => showSubjectDialog(context),
          )
        else
          for (final subStats in subjectStatsList)
            QuickActionSubjectCard(
              key: ValueKey(subStats.subject.id),
              stats: subStats,
              onTap: () => context.push('/subject/${subStats.subject.id}'),
              onPresent: () {
                ref
                    .read(dashboardControllerProvider.notifier)
                    .markPresent(subStats.subject.id);
                showAttendanceUndoSnackBar(
                  context,
                  ref,
                  'Marked ${subStats.subject.name} as Present',
                );
              },
              onAbsent: () {
                ref
                    .read(dashboardControllerProvider.notifier)
                    .markAbsent(subStats.subject.id);
                showAttendanceUndoSnackBar(
                  context,
                  ref,
                  'Marked ${subStats.subject.name} as Absent',
                );
              },
            ),
      ],
    );
  }
}
