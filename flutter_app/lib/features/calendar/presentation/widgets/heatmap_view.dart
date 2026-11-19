import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../providers/calendar_providers.dart';

/// GitHub-style Attendance Contribution Heatmap showing attendance intensity across 26 weeks.
///
/// Exact 1:1 visual and behavioral parity with `react_app/src/components/Heatmap.jsx`.
class HeatmapView extends ConsumerWidget {
  const HeatmapView({super.key});

  static const int weeksToShow = 26;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(heatmapRecordsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final ruleColor = isDark ? AppColors.ruleDark : AppColors.ruleLight;
    final ruleBrightColor =
        isDark ? AppColors.ruleBrightDark : AppColors.ruleBrightLight;

    final recordsMap = heatmapAsync.valueOrNull ?? const {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStrVal = formatDateKey(today);

    // Calculate start date to align with Sunday (Sun = 0)
    // Exactly 26 weeks starting on Sunday, so row 0 is Sunday, row 1 is Mon, row 3 is Wed, row 5 is Fri.
    final startDay = today.subtract(
      Duration(days: (weeksToShow - 1) * 7 + (today.weekday % 7)),
    );

    // Generate dates grouped by weeks (columns)
    final List<List<DateTime>> weeks = [];
    for (int w = 0; w < weeksToShow; w++) {
      final List<DateTime> week = [];
      for (int d = 0; d < 7; d++) {
        week.add(startDay.add(Duration(days: w * 7 + d)));
      }
      weeks.add(week);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Y-Axis Labels: Mon, Wed, Fri
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 2.0),
              child: SizedBox(
                height: 7 * 12.0 + 6 * 4.0, // 7 cells of 12px + 6 gaps of 4px = 108px
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 12), // Sun row spacer
                    Text(
                      'Mon',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 12), // Tue row spacer
                    Text(
                      'Wed',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 12), // Thu row spacer
                    Text(
                      'Fri',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 12), // Sat row spacer
                  ],
                ),
              ),
            ),

            // Horizontal Scrollable Grid of 26 Weeks
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: weeks.map((week) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: week.map((date) {
                          final dateStr = formatDateKey(date);
                          final isFuture = date.isAfter(today);
                          final record = recordsMap[dateStr];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: _buildHeatmapCell(
                              date: date,
                              dateStr: dateStr,
                              isFuture: isFuture,
                              isToday: dateStr == todayStrVal,
                              record: record,
                              ruleColor: ruleColor,
                              ruleBrightColor: ruleBrightColor,
                              paperColor: paperColor,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Legend / Key
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Less',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: mutedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            _buildLegendBox(ruleColor),
            const SizedBox(width: 3),
            _buildLegendBox(AppColors.amber),
            const SizedBox(width: 3),
            _buildLegendBox(AppColors.inkGreen),
            const SizedBox(width: 4),
            Text(
              'More',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: mutedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeatmapCell({
    required DateTime date,
    required String dateStr,
    required bool isFuture,
    required bool isToday,
    required ({int held, int attended, bool isHoliday})? record,
    required Color ruleColor,
    required Color ruleBrightColor,
    required Color paperColor,
  }) {
    Color cellColor;
    String tooltip;

    if (isFuture) {
      cellColor = Colors.transparent;
      tooltip = '';
    } else if (record == null) {
      cellColor = ruleColor;
      tooltip = '$dateStr: Not marked';
    } else if (record.isHoliday || record.held == 0) {
      cellColor = ruleBrightColor;
      tooltip = '$dateStr: Holiday';
    } else if (record.attended == record.held) {
      cellColor = AppColors.inkGreen;
      tooltip = '$dateStr: ${record.attended}/${record.held} classes (100%)';
    } else if (record.attended == 0) {
      cellColor = AppColors.penRed;
      tooltip = '$dateStr: 0/${record.held} classes (0%)';
    } else {
      cellColor = AppColors.amber;
      tooltip = '$dateStr: ${record.attended}/${record.held} classes';
    }

    final widget = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(3),
        border: isToday
            ? Border.all(
                color: paperColor,
                width: 2.0,
              )
            : null,
      ),
    );

    if (isFuture || tooltip.isEmpty) {
      return widget;
    }

    return Tooltip(
      message: tooltip,
      child: widget,
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
