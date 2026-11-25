import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../attendance/domain/entities/legacy_attendance_entity.dart';

/// Quick-action editor panel embedded inside [DayRow] for marking Present, Absent,
/// Holiday / No class, or clearing an existing legacy record.
///
/// Ownership: Register Feature
// ==========================================
// REGISTER - Daily Attendance Action Panel
// ==========================================
class DayAttendanceActionPanel extends StatelessWidget {
  final String dateStr;
  final LegacyAttendanceEntity? legacyRecord;
  final void Function({
    required String date,
    required int held,
    required int attended,
  })
  onSaveDaily;
  final void Function(String id) onDeleteDaily;

  const DayAttendanceActionPanel({
    super.key,
    required this.dateStr,
    required this.legacyRecord,
    required this.onSaveDaily,
    required this.onDeleteDaily,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final ruleBright = isDark
        ? AppColors.ruleBrightDark
        : AppColors.ruleBrightLight;
    final inputBg = isDark ? AppColors.inputBgDark : AppColors.inputBgLight;

    return Container(
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
    );
  }
}
