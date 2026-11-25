import 'package:flutter/material.dart';

import '../../../../shared/widgets/hero_card.dart';
import '../../domain/models/dashboard_stats.dart';

/// Overview card wrapping [HeroCardWidget] to display overall attendance metrics.
///
/// Ownership: Dashboard Feature (UI Widget)
// ==========================================
// DASHBOARD WIDGET - Attendance Overview Ring Card
// ==========================================
class OverviewCard extends StatelessWidget {
  final DashboardStats stats;
  final VoidCallback? onTap;

  const OverviewCard({super.key, required this.stats, this.onTap});

  @override
  Widget build(BuildContext context) {
    return HeroCardWidget(
      conducted: stats.conducted,
      present: stats.present,
      percent: stats.percentage,
      minPercent: stats.minPercent,
      canMiss: stats.canMiss,
      needToAttend: stats.needToAttend,
      isImpossible: stats.isImpossible,
      onTap: onTap,
    );
  }
}
