import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Interactive S-M-T-W-T-F-S weekday toggle chip strip used during onboarding
/// and schedule rules configuration (`0` = Sun .. `6` = Sat).
///
/// Ownership: Shared Form Widgets
// ==========================================
// SHARED WIDGETS - Weekly Class Day Picker
// ==========================================
class DayPickerWidget extends StatelessWidget {
  static const List<String> defaultDayLabels = [
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
  ];

  final List<int> selectedDays;
  final ValueChanged<List<int>> onDaysChanged;
  final List<String> dayLabels;
  final bool enabled;

  const DayPickerWidget({
    super.key,
    required this.selectedDays,
    required this.onDaysChanged,
    this.dayLabels = defaultDayLabels,
    this.enabled = true,
  });

  void _toggleDay(int index) {
    if (!enabled) return;
    final next = List<int>.from(selectedDays);
    if (next.contains(index)) {
      next.remove(index);
    } else {
      next.add(index);
    }
    next.sort();
    onDaysChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(dayLabels.length, (i) {
          final isSelected = selectedDays.contains(i);
          return Padding(
            padding: EdgeInsets.only(
              right: i < dayLabels.length - 1 ? 12.0 : 0.0,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? () => _toggleDay(i) : null,
                borderRadius: BorderRadius.circular(14.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46.0,
                  height: 46.0,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.inkGreen
                        : (isDark
                              ? AppColors.inputBgDark
                              : AppColors.inputBgLight),
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark
                                ? AppColors.ruleBrightDark
                                : AppColors.ruleBrightLight),
                      width: 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.inkGreen.withValues(alpha: 0.30),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayLabels[i],
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : mutedColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
