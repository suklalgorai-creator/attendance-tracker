import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Increment/decrement numeric stepper replicating `react_app/src/components/Stepper.jsx`.
///
/// Ownership: Shared Form Widgets
// ==========================================
// SHARED WIDGETS - Numeric Stepper Control
// ==========================================
class StepperWidget extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool enabled;

  const StepperWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.enabled = true,
  });

  void _decrease() {
    if (!enabled) return;
    onChanged(math.max(min, value - 1));
  }

  void _increase() {
    if (!enabled) return;
    onChanged(math.min(max, value + 1));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final inputBg = isDark ? AppColors.inputBgDark : AppColors.inputBgLight;
    final borderColor = isDark
        ? AppColors.ruleBrightDark
        : AppColors.ruleBrightLight;
    final splashColor = isDark
        ? AppColors.ruleBrightDark
        : AppColors.ruleBrightLight;

    final canDecrease = enabled && value > min;
    final canIncrease = enabled && value < max;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Decrease button
          Semantics(
            label: 'decrease',
            button: true,
            enabled: canDecrease,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10.0),
              child: InkWell(
                onTap: canDecrease ? _decrease : null,
                borderRadius: BorderRadius.circular(10.0),
                hoverColor: splashColor,
                splashColor: splashColor,
                child: SizedBox(
                  width: 40.0,
                  height: 40.0,
                  child: Center(
                    child: Text(
                      '−', // Unicode minus \u2212
                      style: GoogleFonts.outfit(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w400,
                        color: canDecrease
                            ? paperColor
                            : paperColor.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16.0),

          // Value display
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 32.0),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18.0,
                fontWeight: FontWeight.w800,
                color: paperColor,
              ),
            ),
          ),
          const SizedBox(width: 16.0),

          // Increase button
          Semantics(
            label: 'increase',
            button: true,
            enabled: canIncrease,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10.0),
              child: InkWell(
                onTap: canIncrease ? _increase : null,
                borderRadius: BorderRadius.circular(10.0),
                hoverColor: splashColor,
                splashColor: splashColor,
                child: SizedBox(
                  width: 40.0,
                  height: 40.0,
                  child: Center(
                    child: Text(
                      '+',
                      style: GoogleFonts.outfit(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w400,
                        color: canIncrease
                            ? paperColor
                            : paperColor.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
