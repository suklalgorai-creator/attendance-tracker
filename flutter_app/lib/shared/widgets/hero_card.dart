import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import 'attendance_ring.dart';
import 'stat_row_widget.dart';

enum HeroAttendanceStatus {
  safe,
  danger,
  none;

  static HeroAttendanceStatus evaluate(double? percent, double minPercent) {
    if (percent == null) return HeroAttendanceStatus.none;
    return percent >= minPercent
        ? HeroAttendanceStatus.safe
        : HeroAttendanceStatus.danger;
  }
}

/// Replicating `.hero-card` in `react_app/src/pages/DashboardPage.jsx` and `components.css`.
/// Frosted glass container holding `AttendanceRing` alongside stats list (`Conducted`, `Present`, `Status`).
class HeroCardWidget extends StatelessWidget {
  final int conducted;
  final int present;
  final double? percent;
  final double minPercent;
  final int canMiss;
  final int needToAttend;
  final bool isImpossible;
  final String? statusText;
  final VoidCallback? onTap;

  const HeroCardWidget({
    super.key,
    required this.conducted,
    required this.present,
    this.percent,
    this.minPercent = 75.0,
    this.canMiss = 0,
    this.needToAttend = 0,
    this.isImpossible = false,
    String? statusText,
    String? customStatusText,
    this.onTap,
  }) : statusText = statusText ?? customStatusText;

  double? get effectivePercent {
    if (percent != null) return percent;
    if (conducted > 0) return (present / conducted) * 100.0;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    final double? currentPercent = effectivePercent;
    final status = HeroAttendanceStatus.evaluate(currentPercent, minPercent);

    // Border color based on status (.hero-card.safe, .hero-card.danger, .hero-card.none)
    Color borderColor;
    StatValueColor statusVariant;
    switch (status) {
      case HeroAttendanceStatus.safe:
        borderColor = AppColors.inkGreen.withValues(alpha: 0.4);
        statusVariant = StatValueColor.safe;
        break;
      case HeroAttendanceStatus.danger:
        borderColor = AppColors.penRed.withValues(alpha: 0.4);
        statusVariant = StatValueColor.danger;
        break;
      case HeroAttendanceStatus.none:
        borderColor = AppColors.amber.withValues(alpha: 0.4);
        statusVariant = StatValueColor.paper;
        break;
    }

    // Status text formatting matching React DashboardPage.jsx lines 51-53
    String effectiveStatusText;
    if (statusText != null) {
      effectiveStatusText = statusText!;
    } else {
      switch (status) {
        case HeroAttendanceStatus.none:
          effectiveStatusText = 'No attendance recorded';
          break;
        case HeroAttendanceStatus.safe:
          effectiveStatusText = canMiss == 0
              ? 'At the target'
              : 'Can miss $canMiss classes';
          break;
        case HeroAttendanceStatus.danger:
          effectiveStatusText = isImpossible
              ? '100% target is unreachable'
              : 'Need $needToAttend attended classes';
          break;
      }
    }

    final cardContent = LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final bool isCompact = maxWidth < 340;
        final bool isUltraCompact = maxWidth < 300;

        final double ringSize = isUltraCompact
            ? 100.0
            : (isCompact ? 116.0 : 140.0);
        final EdgeInsets cardPadding = isUltraCompact
            ? const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0)
            : (isCompact
                  ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0)
                  : const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 20.0,
                    ));
        final double gap = isUltraCompact ? 8.0 : 10.0;
        final double statsLeftPadding = isUltraCompact
            ? 4.0
            : (isCompact ? 6.0 : 10.0);
        final double statSpacing = isUltraCompact
            ? 8.0
            : (isCompact ? 12.0 : 16.0);

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: cardPadding,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Attendance Ring (responsive size)
                  AttendanceRing(
                    percent: currentPercent,
                    minPercent: minPercent,
                    size: ringSize,
                    animate: true,
                  ),

                  SizedBox(width: gap),

                  // 2. .hero-stats-list
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: statsLeftPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatRowWidget(
                            label: 'Conducted',
                            value: conducted.toString(),
                            isLast: false,
                          ),
                          SizedBox(height: statSpacing),
                          StatRowWidget(
                            label: 'Present',
                            value: present.toString(),
                            isLast: false,
                          ),
                          SizedBox(height: statSpacing),
                          StatRowWidget(
                            label: 'Status',
                            value: effectiveStatusText,
                            valueColor: statusVariant,
                            isStatus: true,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
