import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../attendance/domain/entities/legacy_attendance_entity.dart';
import 'day_action_panel.dart';

/// Single day attendance item replicating `react_app/src/components/DayRow.jsx`.
///
/// Displays date label, TODAY tag, and status indicator. When a day is already
/// marked (`legacyRecord != null`), quick-action buttons stay collapsed until tapped.
///
/// Ownership: Register Feature
// ==========================================
// REGISTER - Daily Attendance Row
// ==========================================
class DayRow extends StatefulWidget {
  final String dateStr;
  final LegacyAttendanceEntity? legacyRecord;
  final bool isToday;
  final bool isHoliday;
  final void Function({
    required String date,
    required int held,
    required int attended,
  })
  onSaveDaily;
  final void Function(String id) onDeleteDaily;

  const DayRow({
    super.key,
    required this.dateStr,
    this.legacyRecord,
    this.isToday = false,
    this.isHoliday = false,
    required this.onSaveDaily,
    required this.onDeleteDaily,
  });

  @override
  State<DayRow> createState() => _DayRowState();
}

class _DayRowState extends State<DayRow> {
  bool _isEditing = false;

  @override
  void didUpdateWidget(covariant DayRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.legacyRecord != widget.legacyRecord &&
        widget.legacyRecord != null) {
      _isEditing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = AppDateUtils.todayStr();
    final future = widget.dateStr.compareTo(today) > 0;
    final editable = !future && !widget.isHoliday;
    final showEditor = editable && (widget.legacyRecord == null || _isEditing);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final ruleColor = isDark ? AppColors.ruleDark : AppColors.ruleLight;

    final (status, statusColor) = _resolveStatus(mutedColor);

    final rowContent = Container(
      margin: const EdgeInsets.only(bottom: 6.0),
      decoration: BoxDecoration(
        color: ruleColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Expandable Row Header
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: editable && widget.legacyRecord != null
                ? () => setState(() => _isEditing = !_isEditing)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppDateUtils.formatDateLabel(widget.dateStr),
                            style: AppTypography.labelLarge.copyWith(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w600,
                              color: paperColor,
                            ),
                          ),
                          if (widget.isToday) ...[
                            const SizedBox(width: 8.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 3.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.inkGreen,
                                borderRadius: BorderRadius.circular(999.0),
                              ),
                              child: Text(
                                'TODAY',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            status,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                        if (editable && widget.legacyRecord != null) ...[
                          const SizedBox(width: 6.0),
                          Icon(
                            _isEditing
                                ? Icons.expand_less_rounded
                                : Icons.edit_outlined,
                            size: 16.0,
                            color: mutedColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Attendance Editor Panel
          if (showEditor)
            DayAttendanceActionPanel(
              dateStr: widget.dateStr,
              legacyRecord: widget.legacyRecord,
              onSaveDaily: ({required date, required held, required attended}) {
                setState(() => _isEditing = false);
                widget.onSaveDaily(date: date, held: held, attended: attended);
              },
              onDeleteDaily: (id) {
                setState(() => _isEditing = false);
                widget.onDeleteDaily(id);
              },
            ),
        ],
      ),
    );

    if (future) {
      return Opacity(opacity: 0.65, child: rowContent);
    }
    return rowContent;
  }

  (String, Color) _resolveStatus(Color mutedColor) {
    final today = AppDateUtils.todayStr();
    final future = widget.dateStr.compareTo(today) > 0;
    final rec = widget.legacyRecord;

    if (widget.isHoliday) return ('Holiday', AppColors.amber);
    if (future) return ('Upcoming', mutedColor);
    if (rec == null) return ('Not marked', mutedColor);
    if (rec.held == 0) return ('Holiday / No class', AppColors.amber);
    if (rec.attended == rec.held) return ('Present', AppColors.inkGreen);
    if (rec.attended == 0) return ('Absent', AppColors.penRed);
    return ('Partial \u00B7 ${rec.attended}/${rec.held}', AppColors.amber);
  }
}
