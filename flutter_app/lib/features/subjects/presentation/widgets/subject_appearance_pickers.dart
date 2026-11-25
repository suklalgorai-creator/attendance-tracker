import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/utils/color_utils.dart';
import 'subject_style_tokens.dart';

/// Color accent swatches, academic icon chips, and custom target threshold
/// controls used by [SubjectDialog].
///
/// Ownership: Subjects Feature
// ==========================================
// SUBJECTS - Color Accent Picker
// ==========================================
class SubjectColorPicker extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const SubjectColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COLOR ACCENT',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: mutedColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kSubjectColors.map((hex) {
            final color = parseHexColor(hex);
            final isSelected = selectedColor.toUpperCase() == hex.toUpperCase();

            return GestureDetector(
              key: Key('color_swatch_$hex'),
              onTap: () => onColorSelected(hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ==========================================
// SUBJECTS - Academic Icon Picker
// ==========================================
class SubjectIconPicker extends StatelessWidget {
  final String selectedIcon;
  final String selectedColor;
  final ValueChanged<String> onIconSelected;

  const SubjectIconPicker({
    super.key,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final activeColor = parseHexColor(selectedColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ICON',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: mutedColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kAcademicIcons.entries.map((entry) {
            final isSelected = selectedIcon == entry.key;

            return GestureDetector(
              key: Key('icon_chip_${entry.key}'),
              onTap: () => onIconSelected(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.2)
                      : (isDark
                            ? AppColors.inputBgDark
                            : AppColors.inputBgLight),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isSelected
                        ? activeColor
                        : (isDark
                              ? AppColors.glassBorderDark
                              : AppColors.glassBorderLight),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Icon(
                  entry.value,
                  size: 20,
                  color: isSelected ? activeColor : mutedColor,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ==========================================
// SUBJECTS - Custom Target Threshold Selector
// ==========================================
class SubjectTargetSection extends StatelessWidget {
  final bool hasCustomTarget;
  final double targetPercentage;
  final String selectedColor;
  final ValueChanged<bool> onToggleChanged;
  final ValueChanged<double> onTargetChanged;

  const SubjectTargetSection({
    super.key,
    required this.hasCustomTarget,
    required this.targetPercentage,
    required this.selectedColor,
    required this.onToggleChanged,
    required this.onTargetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final accentColor = parseHexColor(selectedColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CUSTOM TARGET',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasCustomTarget
                        ? 'Override global target (${targetPercentage.toInt()}%)'
                        : 'Use global threshold (default)',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: mutedColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              key: const Key('custom_target_toggle'),
              value: hasCustomTarget,
              activeThumbColor: AppColors.inkGreen,
              onChanged: onToggleChanged,
            ),
          ],
        ),
        if (hasCustomTarget) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accentColor,
                    thumbColor: accentColor,
                    inactiveTrackColor: isDark
                        ? AppColors.ruleDark
                        : AppColors.ruleLight,
                  ),
                  child: Slider(
                    key: const Key('target_slider'),
                    value: targetPercentage,
                    min: 5.0,
                    max: 100.0,
                    divisions: 19,
                    label: '${targetPercentage.toInt()}%',
                    onChanged: onTargetChanged,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '${targetPercentage.toInt()}%',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
