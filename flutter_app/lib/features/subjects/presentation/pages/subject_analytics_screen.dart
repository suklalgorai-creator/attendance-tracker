import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../shared/widgets/app_banner.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/attendance_ring.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/stat_row_widget.dart';
import '../../../attendance/domain/entities/attendance_record_entity.dart';
import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../dashboard/domain/models/subject_attendance_stats.dart';
import '../../../dashboard/presentation/providers/dashboard_controller.dart';
import '../providers/subject_providers.dart';
import '../widgets/subject_dialog.dart';

/// Detailed analytics and attendance tracking screen for an individual subject.
class SubjectAnalyticsScreen extends ConsumerWidget {
  final String subjectId;

  const SubjectAnalyticsScreen({
    super.key,
    required this.subjectId,
  });

  Color _parseSubjectColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return AppColors.inkGreen;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(subjectDetailStatsProvider(subjectId));
    final historyAsync = ref.watch(subjectHistoryProvider(subjectId));
    final settingsAsync = ref.watch(settingsStreamProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgPrimaryDark : AppColors.bgPrimaryLight,
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load subject details',
                  style: GoogleFonts.outfit(color: AppColors.penRed, fontSize: 16),
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
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: mutedColor,
                        ),
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

            final subject = stats.subject;
            final subjectColor = _parseSubjectColor(subject.color);
            final globalMin = settingsAsync.valueOrNull?.minPercent ?? 75.0;
            final effectiveThreshold = subject.targetPercentage ?? globalMin;
            final iconData = kAcademicIcons[subject.icon] ?? Icons.school_rounded;

            final history = historyAsync.valueOrNull ?? const [];

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              children: [
                // Top App Bar / Navigation Header
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
                        // Target Threshold Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: subject.targetPercentage != null
                                ? AppColors.amberSoft
                                : (isDark ? AppColors.inputBgDark : AppColors.inputBgLight),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: subject.targetPercentage != null
                                  ? AppColors.amber
                                  : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
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
                              color: subject.targetPercentage != null ? AppColors.amber : mutedColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Edit Subject Button
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

                // Subject Title & Meta Card
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
                      child: Icon(
                        iconData,
                        size: 24,
                        color: subjectColor,
                      ),
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
                          if (subject.code != null && subject.code!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.inputBgDark : AppColors.inputBgLight,
                                borderRadius: BorderRadius.circular(AppRadius.xs),
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

                // Attendance Overview Hero Card with AttendanceRing
                GlassCard(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      AttendanceRing(
                        percent: stats.percentage,
                        minPercent: effectiveThreshold,
                        size: 130,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ATTENDANCE',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stats.percentage != null
                                  ? '${stats.percentage!.toStringAsFixed(1)}%'
                                  : '—',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: stats.isSafe ? AppColors.inkGreen : AppColors.penRed,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${stats.present} attended of ${stats.conducted} held',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: paperColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Safe Bunks / Recovery Advisor Banner
                _buildAdvisorBanner(stats, effectiveThreshold),

                const SizedBox(height: 14),

                // Detailed Numerical Stats Breakdown Card
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    children: [
                      StatRowWidget(
                        label: 'CONDUCTED CLASSES',
                        value: '${stats.conducted}',
                      ),
                      StatRowWidget(
                        label: 'PRESENT SESSIONS',
                        value: '${stats.present}',
                        valueColor: StatValueColor.safe,
                      ),
                      StatRowWidget(
                        label: 'ABSENT SESSIONS',
                        value: '${stats.absent}',
                        valueColor: stats.absent > 0 ? StatValueColor.danger : StatValueColor.muted,
                      ),
                      StatRowWidget(
                        label: 'TARGET THRESHOLD',
                        value: '${effectiveThreshold.toInt()}%',
                        valueColor: StatValueColor.amber,
                        isLast: true,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Quick Attendance Action Buttons
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
                          _showUndoSnackBar(
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
                          _showUndoSnackBar(
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

                // Chronological Session History Section
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

                // Session History List or Empty State
                if (history.isEmpty)
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
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
                    _buildSessionHistoryRow(context, record, isDark, paperColor, mutedColor),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdvisorBanner(SubjectAttendanceStats stats, double effectiveThreshold) {
    if (stats.conducted == 0) {
      return const AppBanner.neutral(
        title: 'New Subject',
        message: 'No classes recorded yet. Log attendance to calculate safe bunks.',
      );
    }

    if (stats.isSafe && stats.canMiss > 0) {
      return AppBanner.safe(
        title: 'Safe to Skip',
        message:
            'You can safely miss ${stats.canMiss} ${stats.canMiss == 1 ? 'class' : 'classes'} and stay at or above ${effectiveThreshold.toInt()}%.',
      );
    }

    if (stats.isSafe && stats.canMiss == 0) {
      return AppBanner.neutral(
        title: 'On the Edge',
        message:
            'Your attendance is exactly on target (${stats.percentage!.toStringAsFixed(1)}%). Attend your next class to stay safe.',
      );
    }

    if (stats.isImpossible) {
      return const AppBanner.danger(
        title: 'Target Unreachable',
        message: 'A 100% target is mathematically unreachable with recorded absences.',
      );
    }

    return AppBanner.danger(
      title: 'Action Required',
      message:
          'Attend your next ${stats.needToAttend} consecutive ${stats.needToAttend == 1 ? 'class' : 'classes'} to reach ${effectiveThreshold.toInt()}%.',
    );
  }

  Widget _buildSessionHistoryRow(
    BuildContext context,
    AttendanceRecordEntity record,
    bool isDark,
    Color paperColor,
    Color mutedColor,
  ) {
    final isPresent = record.status == AttendanceStatus.present;
    final statusColor = isPresent ? AppColors.inkGreen : AppColors.penRed;
    final statusBg = isPresent ? AppColors.inkGreenSoft : AppColors.penRedSoft;
    final statusText = isPresent ? 'PRESENT' : 'ABSENT';

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isPresent ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                size: 20,
                color: statusColor,
              ),
              const SizedBox(width: 10),
              Text(
                record.date,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: paperColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
