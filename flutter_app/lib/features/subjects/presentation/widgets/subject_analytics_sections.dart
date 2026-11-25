import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/app_banner.dart';
import '../../../../shared/widgets/attendance_ring.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/stat_row_widget.dart';
import '../../../attendance/domain/entities/attendance_record_entity.dart';
import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../dashboard/domain/models/subject_attendance_stats.dart';

/// Modular display sections used by [SubjectAnalyticsScreen]:
/// overview ring hero card, safe-bunk/recovery advisor banner, metrics breakdown,
/// and chronological session history rows.
///
/// Ownership: Subjects Feature
// ==========================================
// SUBJECT ANALYTICS - Overview Hero Card
// ==========================================
class SubjectAttendanceHeroCard extends StatelessWidget {
  final SubjectAttendanceStats stats;
  final double effectiveThreshold;

  const SubjectAttendanceHeroCard({
    super.key,
    required this.stats,
    required this.effectiveThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GlassCard(
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
    );
  }
}

// ==========================================
// SUBJECT ANALYTICS - Bunk / Recovery Advisor Banner
// ==========================================
class SubjectAdvisorBanner extends StatelessWidget {
  final SubjectAttendanceStats stats;
  final double effectiveThreshold;

  const SubjectAdvisorBanner({
    super.key,
    required this.stats,
    required this.effectiveThreshold,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.conducted == 0) {
      return const AppBanner.neutral(
        title: 'New Subject',
        message:
            'No classes recorded yet. Log attendance to calculate safe bunks.',
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
        message:
            'A 100% target is mathematically unreachable with recorded absences.',
      );
    }

    return AppBanner.danger(
      title: 'Action Required',
      message:
          'Attend your next ${stats.needToAttend} consecutive ${stats.needToAttend == 1 ? 'class' : 'classes'} to reach ${effectiveThreshold.toInt()}%.',
    );
  }
}

// ==========================================
// SUBJECT ANALYTICS - Numerical Stats Breakdown Card
// ==========================================
class SubjectStatsBreakdownCard extends StatelessWidget {
  final SubjectAttendanceStats stats;
  final double effectiveThreshold;

  const SubjectStatsBreakdownCard({
    super.key,
    required this.stats,
    required this.effectiveThreshold,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
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
            valueColor: stats.absent > 0
                ? StatValueColor.danger
                : StatValueColor.muted,
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
    );
  }
}

// ==========================================
// SUBJECT ANALYTICS - Chronological Session History Row
// ==========================================
class SubjectSessionHistoryRow extends StatelessWidget {
  final AttendanceRecordEntity record;

  const SubjectSessionHistoryRow({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
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
          color: isDark
              ? AppColors.glassBorderDark
              : AppColors.glassBorderLight,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isPresent
                    ? Icons.check_circle_outline_rounded
                    : Icons.cancel_outlined,
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
