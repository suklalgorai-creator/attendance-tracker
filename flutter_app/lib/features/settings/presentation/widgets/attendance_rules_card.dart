import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/day_picker_widget.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../providers/settings_controller.dart';

/// Card managing attendance target rules: start date, minimum attendance %,
/// class days of week, and timetable shortcut.
class AttendanceRulesCard extends ConsumerStatefulWidget {
  final UserSettingsEntity settings;

  const AttendanceRulesCard({super.key, required this.settings});

  @override
  ConsumerState<AttendanceRulesCard> createState() =>
      _AttendanceRulesCardState();
}

class _AttendanceRulesCardState extends ConsumerState<AttendanceRulesCard> {
  late final TextEditingController _minPercentController;

  @override
  void initState() {
    super.initState();
    _minPercentController = TextEditingController(
      text: widget.settings.minPercent.toStringAsFixed(1),
    );
  }

  @override
  void didUpdateWidget(covariant AttendanceRulesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentText = _minPercentController.text;
    final parsed = double.tryParse(currentText);
    if (parsed == null || (parsed - widget.settings.minPercent).abs() > 0.05) {
      _minPercentController.text = widget.settings.minPercent.toStringAsFixed(
        1,
      );
    }
  }

  @override
  void dispose() {
    _minPercentController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    DateTime initial = now;
    if (widget.settings.startDate.isNotEmpty) {
      final parsed = DateTime.tryParse(widget.settings.startDate);
      if (parsed != null && !parsed.isAfter(now)) {
        initial = parsed;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.inkGreen,
                    onPrimary: Colors.white,
                    surface: AppColors.bgPrimaryDark,
                    onSurface: AppColors.paperDark,
                  )
                : const ColorScheme.light(
                    primary: AppColors.inkGreen,
                    onPrimary: Colors.white,
                    surface: AppColors.bgPrimaryLight,
                    onSurface: AppColors.paperLight,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      ref.read(settingsControllerProvider.notifier).updateStartDate(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final borderColor = isDark
        ? AppColors.glassBorderDark
        : AppColors.glassBorderLight;
    final inputBg = isDark ? AppColors.inputBgDark : AppColors.inputBgLight;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance Rules', style: AppTypography.cardTitle(paperColor)),
          const SizedBox(height: 16),
          // Classes started on
          Text(
            'CLASSES STARTED ON',
            style: AppTypography.inputLabel(mutedColor),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickStartDate(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.settings.startDate.isNotEmpty
                          ? widget.settings.startDate
                          : 'Select start date (YYYY-MM-DD)',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: widget.settings.startDate.isNotEmpty
                            ? paperColor
                            : mutedColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: mutedColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Minimum attendance required
          Text(
            'MINIMUM ATTENDANCE REQUIRED',
            style: AppTypography.inputLabel(mutedColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _minPercentController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: paperColor,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: inputBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.amber,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    final numVal = double.tryParse(val);
                    if (numVal != null) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .updateMinPercent(numVal);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '%',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: paperColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Which days do you have class?
          Text(
            'WHICH DAYS DO YOU HAVE CLASS?',
            style: AppTypography.inputLabel(mutedColor),
          ),
          const SizedBox(height: 8),
          DayPickerWidget(
            selectedDays: widget.settings.classDays,
            onDaysChanged: (days) {
              ref
                  .read(settingsControllerProvider.notifier)
                  .updateClassDays(days);
            },
          ),
          const SizedBox(height: 20),
          // Timetable link tile
          InkWell(
            onTap: () => context.push('/timetable'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.ruleDark : AppColors.ruleLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const Text('📅', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timetable & Schedule',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: paperColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure weekly recurring subject timetable',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: mutedColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
