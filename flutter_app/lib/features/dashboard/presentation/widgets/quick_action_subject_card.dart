import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/models/subject_attendance_stats.dart';

/// Interactive subject card supporting single-tap "+ Present" and "- Absent"
/// logging with haptic feedback, percentage indicators, and safe bunk chips.
class QuickActionSubjectCard extends StatelessWidget {
  final SubjectAttendanceStats stats;
  final VoidCallback? onPresent;
  final VoidCallback? onAbsent;
  final VoidCallback? onTap;

  const QuickActionSubjectCard({
    super.key,
    required this.stats,
    this.onPresent,
    this.onAbsent,
    this.onTap,
  });

  Color _parseColor(String hex) {
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

  void _handlePresent() {
    HapticFeedback.lightImpact();
    onPresent?.call();
  }

  void _handleAbsent() {
    HapticFeedback.mediumImpact();
    onAbsent?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final subjectColor = _parseColor(stats.subject.color);

    // Percentage string
    final percentageText = stats.percentage != null
        ? '${stats.percentage!.toStringAsFixed(1)}%'
        : '—';

    // Status chip attributes
    String chipLabel;
    Color chipBg;
    Color chipText;

    if (stats.conducted == 0) {
      chipLabel = 'New';
      chipBg = mutedColor.withValues(alpha: 0.12);
      chipText = mutedColor;
    } else if (stats.isSafe && stats.canMiss > 0) {
      chipLabel = '+${stats.canMiss} safe';
      chipBg = AppColors.inkGreenSoft;
      chipText = AppColors.inkGreen;
    } else if (stats.isSafe && stats.canMiss == 0) {
      chipLabel = 'On edge';
      chipBg = AppColors.amberSoft;
      chipText = AppColors.amber;
    } else if (stats.isImpossible) {
      chipLabel = 'Impossible';
      chipBg = AppColors.penRedSoft;
      chipText = AppColors.penRed;
    } else {
      chipLabel = 'Need ${stats.needToAttend}';
      chipBg = AppColors.penRedSoft;
      chipText = AppColors.penRed;
    }

    final cardBorderColor = isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cardBorderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Subject Color Pill + Name + Safe/Recovery Chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: subjectColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: subjectColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stats.subject.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: paperColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        chipLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: chipText,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Metrics Row: Percentage and Conducted/Present Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        percentageText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: stats.isSafe ? AppColors.inkGreen : AppColors.penRed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${stats.present} / ${stats.conducted} classes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.percentage != null
                        ? (stats.percentage! / 100.0).clamp(0.0, 1.0)
                        : 0.0,
                    minHeight: 6,
                    backgroundColor: isDark ? AppColors.ruleDark : AppColors.ruleLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      stats.conducted == 0
                          ? mutedColor
                          : (stats.isSafe ? AppColors.inkGreen : AppColors.penRed),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Action Buttons: "+ Present" and "- Absent"
                Row(
                  children: [
                    Expanded(
                      child: AppButton.present(
                        label: '+ Present',
                        onPressed: _handlePresent,
                        fontSize: 13.0,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton.absent(
                        label: '- Absent',
                        onPressed: _handleAbsent,
                        fontSize: 13.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
