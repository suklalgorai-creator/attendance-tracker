import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// App header component replicating AppLayout.jsx header:
/// - Hamburger menu button (opens Drawer)
/// - Uppercase amber eyebrow (program name / fallback 'ATTENDANCE REGISTER')
/// - Gradient title (course name / fallback 'My Attendance')
/// - Theme toggle button (☀️ / 🌙)
/// - Flame streak pill badge (🔥 X, displayed when streak > 0)
class AppHeader extends ConsumerWidget {
  final VoidCallback? onMenuPressed;
  final String? programName;
  final String? courseName;
  final int streak;

  const AppHeader({
    super.key,
    this.onMenuPressed,
    this.programName,
    this.courseName,
    this.streak = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceHoverDark : AppColors.surfaceHoverLight;
    final borderColor = isDark ? AppColors.ruleBrightDark : AppColors.ruleBrightLight;

    final gradStart = isDark ? AppColors.textGradientStartDark : AppColors.textGradientStartLight;
    final gradEnd = isDark ? AppColors.textGradientEndDark : AppColors.textGradientEndLight;

    final eyebrowText = programName != null && programName!.isNotEmpty
        ? programName!.toUpperCase()
        : 'ATTENDANCE REGISTER';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Hamburger + Eyebrow & Course Title
          Expanded(
            child: Row(
              children: [
                InkWell(
                  onTap: onMenuPressed,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      size: 20,
                      color: isDark ? AppColors.paperDark : AppColors.paperLight,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        eyebrowText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.eyebrow(AppColors.amber),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [gradStart, gradEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          courseName ?? 'My Attendance',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.courseTitle(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right: Theme Toggle & Streak Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Text(
                    isDark ? '☀️' : '🌙',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              if (streak > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppColors.amber, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '$streak',
                        style: AppTypography.statLabel(AppColors.amber).copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
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
