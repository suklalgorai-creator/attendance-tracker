import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/calendar_day_summary.dart';

/// Day cell, stat footer column, and dashed rule painter used inside [CalendarViewWidget].
///
/// Ownership: Calendar Feature
// ==========================================
// CALENDAR - Individual Day Cell
// Renders attendance status badge (present/absent/partial/holiday/empty) with tooltip.
// ==========================================
class CalendarDayCell extends StatelessWidget {
  final int dayNumber;
  final CalendarDaySummary summary;
  final bool isToday;
  final Color paperColor;
  final Color mutedColor;

  const CalendarDayCell({
    super.key,
    required this.dayNumber,
    required this.summary,
    required this.isToday,
    required this.paperColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final (cellBgColor, textColor) = switch (summary.type) {
      CalendarDayType.empty => (
        Colors.transparent,
        mutedColor.withValues(alpha: 0.5),
      ),
      CalendarDayType.present => (AppColors.amber, Colors.white),
      CalendarDayType.absent => (AppColors.penRed, Colors.white),
      CalendarDayType.partial => (AppColors.amber, Colors.white),
      CalendarDayType.holiday => (const Color(0xFF3B82F6), Colors.white),
    };

    final tooltipMsg = switch (summary.type) {
      CalendarDayType.empty => '${summary.date}: No attendance recorded',
      CalendarDayType.holiday => '${summary.date}: Holiday',
      CalendarDayType.present ||
      CalendarDayType.absent ||
      CalendarDayType.partial =>
        '${summary.date}: ${summary.attended}/${summary.held} attended',
    };

    return Tooltip(
      message: tooltipMsg,
      child: Container(
        decoration: BoxDecoration(
          color: cellBgColor,
          shape: BoxShape.circle,
          border: isToday ? Border.all(color: paperColor, width: 2.0) : null,
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
}

// ==========================================
// CALENDAR - Monthly Summary Stat Column
// ==========================================
class CalendarStatColumn extends StatelessWidget {
  final String label;
  final int value;
  final Color valueColor;
  final Color mutedColor;

  const CalendarStatColumn({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
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
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CALENDAR - Dashed Rule Divider Painter
// ==========================================
class CalendarDashedRulePainter extends CustomPainter {
  final Color color;

  const CalendarDashedRulePainter({required this.color});

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
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CalendarDashedRulePainter oldDelegate) =>
      oldDelegate.color != color;
}
