import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/dashboard_stats.dart';
import '../providers/dashboard_controller.dart';
import '../providers/dashboard_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../widgets/advisor_banner.dart';
import '../widgets/empty_dashboard_view.dart';
import '../widgets/overview_card.dart';
import '../widgets/quick_action_subject_card.dart';
import '../widgets/streak_badge.dart';

/// Main Dashboard Page displaying attendance overview, safe bunk advisor,
/// streak indicators, and quick action subject cards.
class DashboardPage extends ConsumerWidget {
  final VoidCallback? onAddSubject;

  const DashboardPage({
    super.key,
    this.onAddSubject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final subjectStatsAsync = ref.watch(subjectStatsListProvider);
    final streakAsync = ref.watch(streakCountProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);

    final stats = statsAsync.valueOrNull ?? DashboardStats.empty();
    final subjectStatsList = subjectStatsAsync.valueOrNull ?? const [];
    final streak = streakAsync.valueOrNull ?? 0;
    final settings = settingsAsync.valueOrNull;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        // Header Row: Title ('Dashboard'), Program/Course subtitle, and Streak Pill
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: paperColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (settings?.programName.isNotEmpty ?? false)
                        ? settings!.programName
                        : 'Semester Overview',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            StreakBadge(streak: streak),
          ],
        ),

        const SizedBox(height: 16),

        // Advisor Banner
        AdvisorBanner(
          stats: stats,
        ),

        const SizedBox(height: 16),

        // Overview Hero Card
        OverviewCard(
          stats: stats,
        ),

        const SizedBox(height: 24),

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
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: paperColor,
                ),
              ),
            ),
            if (subjectStatsList.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '${subjectStatsList.length} ${subjectStatsList.length == 1 ? 'subject' : 'subjects'}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: mutedColor,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // Subject Cards or Empty State Placeholder
        if (subjectStatsList.isEmpty)
          EmptyDashboardView(
            onAddSubject: onAddSubject,
          )
        else
          for (final subStats in subjectStatsList)
            QuickActionSubjectCard(
              key: ValueKey(subStats.subject.id),
              stats: subStats,
              onPresent: () {
                ref
                    .read(dashboardControllerProvider.notifier)
                    .markPresent(subStats.subject.id);
                _showUndoSnackBar(
                  context,
                  ref,
                  'Marked ${subStats.subject.name} as Present',
                );
              },
              onAbsent: () {
                ref
                    .read(dashboardControllerProvider.notifier)
                    .markAbsent(subStats.subject.id);
                _showUndoSnackBar(
                  context,
                  ref,
                  'Marked ${subStats.subject.name} as Absent',
                );
              },
            ),
      ],
    );
  }

  void _showUndoSnackBar(BuildContext context, WidgetRef ref, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(dashboardControllerProvider.notifier).undoLastAction();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
