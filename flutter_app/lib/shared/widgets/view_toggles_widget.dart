import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

enum RegisterViewMode {
  week('Week'),
  month('Month'),
  all('All');

  final String label;
  const RegisterViewMode(this.label);
}

/// Segmented toggle pills replicating `.view-toggles` in React
/// Supports Week, Month, All view options.
class ViewTogglesWidget extends StatelessWidget {
  final RegisterViewMode currentMode;
  final ValueChanged<RegisterViewMode> onModeChanged;
  final List<RegisterViewMode> modes;

  const ViewTogglesWidget({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.modes = RegisterViewMode.values,
  });

  RegisterViewMode get selectedMode => currentMode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ruleColor = isDark ? AppColors.ruleDark : AppColors.ruleLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: ruleColor,
        borderRadius: BorderRadius.circular(AppRadius.sm), // 8.0px
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: modes.map((mode) {
          final isActive = mode == currentMode;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onModeChanged(mode),
                borderRadius: BorderRadius.circular(6.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? surfaceColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6.0),
                    boxShadow: isActive
                        ? [
                            const BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    mode.label.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isActive ? paperColor : mutedColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
