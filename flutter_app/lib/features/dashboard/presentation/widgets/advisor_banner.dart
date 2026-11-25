import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_banner.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/models/dashboard_stats.dart';

/// Smart advisor banner displaying safe bunk advice, recovery requirements, or session alerts.
///
/// Ownership: Dashboard Feature (UI Widget)
// ==========================================
// DASHBOARD WIDGET - Attendance Advisor Banner
// ==========================================
class AdvisorBanner extends StatelessWidget {
  final DashboardStats stats;
  final VoidCallback? onReviewUnmarked;

  const AdvisorBanner({super.key, required this.stats, this.onReviewUnmarked});

  @override
  Widget build(BuildContext context) {
    // 1. Unmarked past sessions take priority
    if (stats.unmarkedPastSessions > 0) {
      return AppBanner.reminder(
        title: 'Unmarked Sessions',
        message:
            'You have ${stats.unmarkedPastSessions} unmarked past session${stats.unmarkedPastSessions == 1 ? '' : 's'}. Review now to keep your records accurate.',
        action: onReviewUnmarked != null
            ? AppButton.absent(
                label: 'Review',
                fontSize: 12.0,
                onPressed: onReviewUnmarked,
              )
            : null,
      );
    }

    // 2. Zero conducted sessions
    if (stats.conducted == 0) {
      return const AppBanner.neutral(
        title: 'Welcome to Attendance Tracker',
        message:
            'Log your first class to see smart attendance advice and safe bunk calculations.',
      );
    }

    // 3. Safe zone with allowable bunks
    if (stats.isSafe && stats.canMiss > 0) {
      final plural = stats.canMiss == 1 ? 'class' : 'classes';
      return AppBanner.safe(
        title: 'Safe to Bunk',
        message:
            'You can safely miss ${stats.canMiss} $plural while staying above ${stats.minPercent.toInt()}%.',
      );
    }

    // 4. Safe zone exactly on the edge (canMiss == 0)
    if (stats.isSafe && stats.canMiss == 0) {
      return AppBanner.neutral(
        title: 'On the Edge',
        message:
            'You are right at your ${stats.minPercent.toInt()}% target. Any absence will drop you into the danger zone.',
      );
    }

    // 5. Danger zone - 100% target unreachable
    if (!stats.isSafe && stats.isImpossible) {
      return const AppBanner.danger(
        title: 'Target Unreachable',
        message: 'A 100% target is mathematically unreachable this semester.',
      );
    }

    // 6. Danger zone - recovery classes needed
    final plural = stats.needToAttend == 1 ? 'class' : 'classes';
    return AppBanner.danger(
      title: 'Attendance Warning',
      message:
          'Attend next ${stats.needToAttend} consecutive $plural to recover to ${stats.minPercent.toInt()}%.',
    );
  }
}
