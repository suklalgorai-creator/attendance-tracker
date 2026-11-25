import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/undo_snack_bar.dart';
import '../../../dashboard/presentation/providers/dashboard_controller.dart';
import '../providers/subject_providers.dart';
import '../widgets/subject_analytics_sections.dart';
import '../widgets/subject_dialog.dart';

/// Detailed analytics and attendance tracking screen for an individual subject.
///
/// Ownership: Subjects Feature
// ==========================================
// SUBJECT ANALYTICS - Main Screen
// ==========================================
class SubjectAnalyticsScreen extends ConsumerWidget {
  final String subjectId;

  const SubjectAnalyticsScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(subjectDetailStatsProvider(subjectId));
    final historyAsync = ref.watch(subjectHistoryProvider(subjectId));
    final settingsAsync = ref.watch(settingsStreamProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.bgPrimaryDark
          : AppColors.bgPrimaryLight,
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load subject details',
                  style: GoogleFonts.outfit(
                    color: AppColors.penRed,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                AppButton.ghost(
                  label: 'Go Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          data: (stats) {
            if (stats == null) {
              return _SubjectNotFoundView(
                paperColor: paperColor,
                mutedColor: mutedColor,
              );
            }

            final subject = stats.subject;
            final subjectColor = parseHexColor(subject.color);
            final globalMin = settingsAsync.valueOrNull?.minPercent ?? 75.0;
            final effectiveThreshold = subject.targetPercentage ?? globalMin;
            final iconData =
                kAcademicIcons[subject.icon] ?? Icons.school_rounded;
            final history = historyAsync.valueOrNull ?? const [];

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              children: [
                // Top Navigation & Target Badge Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      key: const Key('subject_back_button'),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: paperColor,
                      tooltip: 'Back to Dashboard',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: subject.targetPercentage != null
                                ? AppColors.amberSoft
                                : (isDark
                                      ? AppColors.inputBgDark
                                      : AppColors.inputBgLight),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: subject.targetPercentage != null
                                  ? AppColors.amber
                                  : (isDark
                                        ? AppColors.glassBorderDark
                                        : AppColors.glassBorderLight),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            subject.targetPercentage != null
                                ? 'TARGET ${effectiveThreshold.toInt()}%'
                                : 'GLOBAL ${effectiveThreshold.toInt()}%',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: subject.targetPercentage != null
                                  ? AppColors.amber
                                  : mutedColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          key: const Key('edit_subject_button'),
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          color: paperColor,
                          tooltip: 'Edit Subject',
                          onPressed: () {
                            showSubjectDialog(
                              context,
                              subject: subject,
                              onDeleted: () {
                                if (context.mounted) {
                                  Navigator.of(context).maybePop();
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Subject Identity Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: subjectColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: subjectColor, width: 1.5),
                      ),
                      child: Icon(iconData, size: 24, color: subjectColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: paperColor,
                            ),
                          ),
                          if (subject.code != null &&
                              subject.code!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.inputBgDark
                                    : AppColors.inputBgLight,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xs,
                                ),
                              ),
                              child: Text(
                                subject.code!,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: mutedColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Attendance Ring Hero Card
                SubjectAttendanceHeroCard(
                  stats: stats,
                  effectiveThreshold: effectiveThreshold,
                ),
                const SizedBox(height: 14),

                // Safe Bunk / Recovery Banner
                SubjectAdvisorBanner(
                  stats: stats,
                  effectiveThreshold: effectiveThreshold,
                ),
                const SizedBox(height: 14),

                // Metrics Breakdown Card
                SubjectStatsBreakdownCard(
                  stats: stats,
                  effectiveThreshold: effectiveThreshold,
                ),
                const SizedBox(height: 18),

                // Quick Present / Absent Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppButton.present(
                        key: const Key('analytics_present_button'),
                        label: '+ Present',
                        onPressed: () {
                          ref
                              .read(dashboardControllerProvider.notifier)
                              .markPresent(subject.id);
                          showAttendanceUndoSnackBar(
                            context,
                            ref,
                            'Marked ${subject.name} as Present',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton.absent(
                        key: const Key('analytics_absent_button'),
                        label: '- Absent',
                        onPressed: () {
                          ref
                              .read(dashboardControllerProvider.notifier)
                              .markAbsent(subject.id);
                          showAttendanceUndoSnackBar(
                            context,
                            ref,
                            'Marked ${subject.name} as Absent',
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Chronological Session History Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Session History',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: paperColor,
                      ),
                    ),
                    Text(
                      '${history.length} ${history.length == 1 ? 'class' : 'classes'}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Session History List or Empty Placeholder
                if (history.isEmpty)
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 28.0,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 40,
                            color: mutedColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No classes recorded yet for this subject',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: paperColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Use the buttons above to log your first class.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final record in history)
                    SubjectSessionHistoryRow(record: record),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SubjectNotFoundView extends StatelessWidget {
  final Color paperColor;
  final Color mutedColor;

  const _SubjectNotFoundView({
    required this.paperColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: mutedColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Subject Not Found',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: paperColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This subject may have been deleted or does not exist.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: mutedColor),
            ),
            const SizedBox(height: 24),
            AppButton.present(
              key: const Key('not_found_back_button'),
              label: 'Return to Dashboard',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
