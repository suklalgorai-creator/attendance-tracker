import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../providers/calendar_providers.dart';
import 'calendar_view.dart';
import 'heatmap_view.dart';

/// Activity Card container switching between monthly Calendar View and
/// 26-week Contribution Heatmap (`react_app/src/pages/DashboardPage.jsx`).
///
/// Ownership: Calendar Feature (UI Widget)
// ==========================================
// CALENDAR WIDGET - Activity Card Container
// ==========================================
class ActivityCard extends ConsumerWidget {
  const ActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(calendarViewModeProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: 'Activity' Title + View Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Activity',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: paperColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Segmented Toggle Pills: Calendar vs Heatmap
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.ruleDark : AppColors.ruleLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(2.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleTab(
                          label: 'Month',
                          icon: Icons.calendar_month_rounded,
                          isSelected: viewMode == CalendarViewMode.calendar,
                          paperColor: paperColor,
                          mutedColor: mutedColor,
                          onTap: () {
                            ref.read(calendarViewModeProvider.notifier).state =
                                CalendarViewMode.calendar;
                          },
                        ),
                        _buildToggleTab(
                          label: 'Heatmap',
                          icon: Icons.grid_view_rounded,
                          isSelected: viewMode == CalendarViewMode.heatmap,
                          paperColor: paperColor,
                          mutedColor: mutedColor,
                          onTap: () {
                            ref.read(calendarViewModeProvider.notifier).state =
                                CalendarViewMode.heatmap;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Active View: Calendar vs Heatmap
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: viewMode == CalendarViewMode.calendar
                ? const CalendarViewWidget(key: ValueKey('calendar_view'))
                : const HeatmapView(key: ValueKey('heatmap_view')),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color paperColor,
    required Color mutedColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amberSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.amber : mutedColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.amber : mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
