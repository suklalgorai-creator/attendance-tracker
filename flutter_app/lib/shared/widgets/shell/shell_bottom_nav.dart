import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

/// Mobile bottom navigation bar switching between the 5 StatefulShell branches.
///
/// Ownership: Shared Shell Navigation
// ==========================================
// SHELL - Mobile Bottom Navigation Bar
// Renders Home, Register, DailyFlow, Leaderboard, and Profile tabs.
// ==========================================
class ShellBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const ShellBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDark
        ? const Color(0xEB18181B)
        : const Color(0xEBFFFFFF);
    final borderColor = isDark
        ? AppColors.ruleBrightDark
        : AppColors.ruleBrightLight;

    return Container(
      decoration: BoxDecoration(
        color: navBgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _NavBarItem(
                label: 'Home',
                icon: Icons.home_rounded,
                isActive: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
            ),
            Expanded(
              child: _NavBarItem(
                label: 'Register',
                icon: Icons.calendar_today_rounded,
                isActive: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),
            ),
            Expanded(
              child: _NavBarItem(
                label: 'DailyFlow',
                icon: Icons.bolt_rounded,
                isActive: currentIndex == 2,
                onTap: () => onTabSelected(2),
              ),
            ),
            Expanded(
              child: _NavBarItem(
                label: 'Leaderboard',
                icon: Icons.emoji_events_rounded,
                isActive: currentIndex == 3,
                onTap: () => onTabSelected(3),
              ),
            ),
            Expanded(
              child: _NavBarItem(
                label: 'Profile',
                icon: Icons.person_rounded,
                isActive: currentIndex == 4,
                onTap: () => onTabSelected(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.inkGreenSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                size: 22,
                color: isActive ? AppColors.inkGreen : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.navLabel(
                isActive ? AppColors.inkGreen : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
