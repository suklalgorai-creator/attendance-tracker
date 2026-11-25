import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../attendance/domain/entities/legacy_attendance_entity.dart';

/// Single day attendance item replicating `react_app/src/components/DayRow.jsx`.
///
/// Features:
/// - Date label formatted with [formatDateLabel] + "today" badge when [isToday] is true.
/// - Status label computed across 7 distinct states:
///   Holiday, Upcoming, Not marked, Present, Absent, Partial · X/Y, Holiday / No class.
/// - 65% opacity on future dates (`dateStr > todayStr()`).
/// - Inline custom editor when editable (`!future && !isHoliday`) featuring 4 action buttons
///   (Present, Absent, Holiday / No class, Clear) in a responsive 2-row layout guaranteed
///   never to overflow on narrow 320px screens.
class DayRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final today = AppDateUtils.todayStr();
    final future = dateStr.compareTo(today) > 0;
    final editable = !future && !isHoliday;

    final String status;
    final Color statusColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final ruleColor = isDark ? AppColors.ruleDark : AppColors.ruleLight;
    final ruleBright = isDark
        ? AppColors.ruleBrightDark
        : AppColors.ruleBrightLight;
    final inputBg = isDark ? AppColors.inputBgDark : AppColors.inputBgLight;

    if (isHoliday) {
      status = 'Holiday';
      statusColor = AppColors.amber;
    } else if (future) {
      status = 'Upcoming';
      statusColor = mutedColor;
    } else if (legacyRecord == null) {
      status = 'Not marked';
      statusColor = mutedColor;
    } else if (legacyRecord!.held == 0) {
      status = 'Holiday / No class';
      statusColor = AppColors.amber;
    } else if (legacyRecord!.attended == legacyRecord!.held) {
      status = 'Present';
      statusColor = AppColors.inkGreen;
    } else if (legacyRecord!.attended == 0) {
      status = 'Absent';
      statusColor = AppColors.penRed;
    } else {
      status = 'Partial · ${legacyRecord!.attended}/${legacyRecord!.held}';
      statusColor = AppColors.amber;
    }

    final rowContent = Container(
      margin: const EdgeInsets.only(bottom: 6.0),
      decoration: BoxDecoration(
        color: ruleColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date label & Today badge
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppDateUtils.formatDateLabel(dateStr),
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w600,
                            color: paperColor,
                          ),
                        ),
                        if (isToday) ...[
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

                // Status text
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
              ],
            ),
          ),

          // Custom editor section (if editable)
          if (editable)
            Container(
              margin: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: ruleBright, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY ATTENDANCE',
                    style: GoogleFonts.outfit(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // Responsive 2-row button layout
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.present(
                          label: 'Present',
                          padding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 8.0,
                          ),
                          fontSize: 13.0,
                          onPressed: () =>
                              onSaveDaily(date: dateStr, held: 1, attended: 1),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: AppButton.absent(
                          label: 'Absent',
                          padding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 8.0,
                          ),
                          fontSize: 13.0,
                          onPressed: () =>
                              onSaveDaily(date: dateStr, held: 1, attended: 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        flex: legacyRecord != null ? 3 : 1,
                        child: AppButton.ghost(
                          label: 'Holiday / No class',
                          padding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 8.0,
                          ),
                          fontSize: 13.0,
                          onPressed: () =>
                              onSaveDaily(date: dateStr, held: 0, attended: 0),
                        ),
                      ),
                      if (legacyRecord != null) ...[
                        const SizedBox(width: 8.0),
                        Expanded(
                          flex: 2,
                          child: AppButton.clear(
                            label: 'Clear',
                            padding: const EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 8.0,
                            ),
                            fontSize: 13.0,
                            onPressed: () => onDeleteDaily(legacyRecord!.id),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    if (future) {
      return Opacity(opacity: 0.65, child: rowContent);
    }

    return rowContent;
  }
}
