import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/models/calendar_day_summary.dart';
import '../providers/calendar_providers.dart';

/// Month names matching React `CalendarView.jsx`.
const List<String> _kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Day header names matching React `CalendarView.jsx`.
const List<String> _kDayNames = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

/// Monthly interactive Calendar View displaying attendance dots and summary stats.
///
/// Exact 1:1 visual and behavioral parity with `react_app/src/components/CalendarView.jsx`.
class CalendarViewWidget extends ConsumerWidget {
  const CalendarViewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedDate = ref.watch(calendarDateProvider);
    final daysAsync = ref.watch(calendarDaysInMonthProvider);
    final summaryAsync = ref.watch(calendarMonthSummaryProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final ruleBrightColor =
        isDark ? AppColors.ruleBrightDark : AppColors.ruleBrightLight;

    final year = focusedDate.year;
    final month = focusedDate.month;
    final today = todayStr();

    // Day of week of the 1st day of the month (0 = Sun .. 6 = Sat)
    final firstDayWeekday = DateTime(year, month, 1).weekday % 7;

    final daySummaries = daysAsync.valueOrNull ?? const [];
    final monthSummary =
        summaryAsync.valueOrNull ?? const CalendarMonthSummary.empty();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Calendar Navigation Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              key: const Key('calendar_prev_month_btn'),
              icon: const Text(
                '‹',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              color: paperColor,
              tooltip: 'Previous month',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                ref.read(calendarDateProvider.notifier).prevMonth();
              },
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${_kMonthNames[month - 1]} $year',
                    key: const Key('calendar_title'),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: paperColor,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              key: const Key('calendar_next_month_btn'),
              icon: const Text(
                '›',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              color: paperColor,
              tooltip: 'Next month',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                ref.read(calendarDateProvider.notifier).nextMonth();
              },
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Day Headers: Su, Mo, Tu, We, Th, Fr, Sa
        Row(
          children: _kDayNames.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: mutedColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 8),

        // Calendar Days Grid
        if (daysAsync.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
            ),
          )
        else
          _buildMonthGrid(
            context: context,
            firstDayWeekday: firstDayWeekday,
            daySummaries: daySummaries,
            today: today,
            paperColor: paperColor,
            mutedColor: mutedColor,
          ),

        const SizedBox(height: 16),

        // Dashed Divider separating grid from summary
        CustomPaint(
          size: const Size(double.infinity, 1),
          painter: _DashedRulePainter(color: ruleBrightColor),
        ),

        const SizedBox(height: 16),

        // Monthly Summary Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _buildStatColumn(
                'Conducted',
                monthSummary.held,
                paperColor,
                mutedColor,
              ),
            ),
            Expanded(
              child: _buildStatColumn(
                'Present',
                monthSummary.attended,
                paperColor,
                mutedColor,
              ),
            ),
            Expanded(
              child: _buildStatColumn(
                'Holidays',
                monthSummary.holidays,
                paperColor,
                mutedColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthGrid({
    required BuildContext context,
    required int firstDayWeekday,
    required List<CalendarDaySummary> daySummaries,
    required String today,
    required Color paperColor,
    required Color mutedColor,
  }) {
    // Total cells = leading padding cells + total days in month
    final totalCells = firstDayWeekday + daySummaries.length;
    final totalRows = (totalCells / 7).ceil();

    final List<Widget> rowWidgets = [];

    for (int r = 0; r < totalRows; r++) {
      final List<Widget> dayCellWidgets = [];

      for (int c = 0; c < 7; c++) {
        final cellIndex = r * 7 + c;

        if (cellIndex < firstDayWeekday ||
            cellIndex >= firstDayWeekday + daySummaries.length) {
          // Empty padding cell
          dayCellWidgets.add(
            const Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: SizedBox.shrink(),
              ),
            ),
          );
        } else {
          final daySummary = daySummaries[cellIndex - firstDayWeekday];
          final dayNumber = cellIndex - firstDayWeekday + 1;
          final isToday = daySummary.date == today;

          dayCellWidgets.add(
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: _buildDayCell(
                    dayNumber: dayNumber,
                    summary: daySummary,
                    isToday: isToday,
                    paperColor: paperColor,
                    mutedColor: mutedColor,
                  ),
                ),
              ),
            ),
          );
        }
      }

      rowWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(children: dayCellWidgets),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rowWidgets,
    );
  }

  Widget _buildDayCell({
    required int dayNumber,
    required CalendarDaySummary summary,
    required bool isToday,
    required Color paperColor,
    required Color mutedColor,
  }) {
    // Styling matching React `components.css` lines 358-370
    Color cellBgColor;
    Color textColor;

    switch (summary.type) {
      case CalendarDayType.empty:
        cellBgColor = Colors.transparent;
        textColor = mutedColor.withValues(alpha: 0.5);
        break;
      case CalendarDayType.present:
        cellBgColor = AppColors.amber;
        textColor = Colors.white;
        break;
      case CalendarDayType.absent:
        cellBgColor = AppColors.penRed;
        textColor = Colors.white;
        break;
      case CalendarDayType.partial:
        cellBgColor = AppColors.amber;
        textColor = Colors.white;
        break;
      case CalendarDayType.holiday:
        cellBgColor = const Color(0xFF3B82F6);
        textColor = Colors.white;
        break;
    }

    String tooltipMsg;
    switch (summary.type) {
      case CalendarDayType.empty:
        tooltipMsg = '${summary.date}: No attendance recorded';
        break;
      case CalendarDayType.holiday:
        tooltipMsg = '${summary.date}: Holiday';
        break;
      case CalendarDayType.present:
      case CalendarDayType.absent:
      case CalendarDayType.partial:
        tooltipMsg = '${summary.date}: ${summary.attended}/${summary.held} attended';
        break;
    }

    return Tooltip(
      message: tooltipMsg,
      child: Container(
        decoration: BoxDecoration(
          color: cellBgColor,
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(
                  color: paperColor,
                  width: 2.0,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$dayNumber',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
            color: isToday && summary.type == CalendarDayType.empty
                ? paperColor
                : textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    int value,
    Color paperColor,
    Color mutedColor,
  ) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: paperColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for dashed rule divider matching `var(--rule-bright)`
class _DashedRulePainter extends CustomPainter {
  final Color color;

  const _DashedRulePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedRulePainter oldDelegate) =>
      oldDelegate.color != color;
}
