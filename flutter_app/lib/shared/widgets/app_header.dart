import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../features/sync/presentation/widgets/sync_indicator_widget.dart';
import 'streak_popup_dialog.dart';

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
  final bool showMenuButton;

  const AppHeader({
    super.key,
    this.onMenuPressed,
    this.programName,
    this.courseName,
    this.streak = 0,
    this.showMenuButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceHoverDark
        : AppColors.surfaceHoverLight;
    final borderColor = isDark
        ? AppColors.ruleBrightDark
        : AppColors.ruleBrightLight;

    final gradStart = isDark
        ? AppColors.textGradientStartDark
        : AppColors.textGradientStartLight;
    final gradEnd = isDark
        ? AppColors.textGradientEndDark
        : AppColors.textGradientEndLight;

    final eyebrowParts = [
      if (programName != null && programName!.trim().isNotEmpty)
        programName!.trim(),
      if (courseName != null && courseName!.trim().isNotEmpty)
        courseName!.trim(),
    ];
    final eyebrowText = eyebrowParts.isEmpty
        ? 'ATTENDANCE REGISTER'
        : eyebrowParts.join(' • ').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Hamburger + Eyebrow & Course Title
          Expanded(
            child: Row(
              children: [
                if (showMenuButton) ...[
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
                        color: isDark
                            ? AppColors.paperDark
                            : AppColors.paperLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
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
                          'My Attendance',
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
          // Right: Sync Indicator, Theme Toggle & Streak Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SyncIndicatorWidget(),
              const SizedBox(width: AppSpacing.sm),
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
                Semantics(
                  button: true,
                  label: '$streak day streak, tap to view details',
                  child: InkWell(
                    key: const Key('header_streak_button'),
                    onTap: () => showStreakDialog(context, streak: streak),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
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
                            style: AppTypography.statLabel(
                              AppColors.amber,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
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
