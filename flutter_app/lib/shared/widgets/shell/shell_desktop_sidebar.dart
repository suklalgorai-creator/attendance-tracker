import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../features/settings/presentation/providers/settings_controller.dart';
import 'shell_actions.dart';

/// Collapsible desktop navigation sidebar rendered on viewports >= 1024px.
///
/// Ownership: Shared Shell Navigation
// ==========================================
// SHELL - Desktop Navigation Sidebar
// Provides collapsible primary branch tabs and utility shortcuts.
// ==========================================
class ShellDesktopSidebar extends ConsumerWidget {
  final bool collapsed;
  final int currentIndex;
  final VoidCallback onCollapseToggle;
  final ValueChanged<int> onTabSelected;

  const ShellDesktopSidebar({
    super.key,
    required this.collapsed,
    required this.currentIndex,
    required this.onCollapseToggle,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: collapsed ? 88 : 260,
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 16 : 24,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          right: BorderSide(
            color: isDark
                ? AppColors.ruleBrightDark
                : AppColors.ruleBrightLight,
          ),
        ),
      ),
      child: Column(
        children: [
          // Brand Header & Collapse Toggle
          Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
            children: [
              if (!collapsed)
                Row(
                  children: [
                    const Text('🎓', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      'Attendance',
                      style: AppTypography.cardTitle(
                        paper,
                      ).copyWith(fontSize: 20),
                    ),
                  ],
                ),
              IconButton(
                tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                onPressed: onCollapseToggle,
                icon: Icon(Icons.menu_rounded, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Primary Tab Branches
          _SidebarItem(
            label: 'Dashboard',
            icon: Icons.home_outlined,
            active: currentIndex == 0,
            collapsed: collapsed,
            onTap: () => onTabSelected(0),
          ),
          _SidebarItem(
            label: 'Register',
            icon: Icons.calendar_today_outlined,
            active: currentIndex == 1,
            collapsed: collapsed,
            onTap: () => onTabSelected(1),
          ),
          _SidebarItem(
            label: 'DailyFlow',
            icon: Icons.bolt_rounded,
            active: currentIndex == 2,
            collapsed: collapsed,
            onTap: () => onTabSelected(2),
          ),
          _SidebarItem(
            label: 'Leaderboard',
            icon: Icons.emoji_events_outlined,
            active: currentIndex == 3,
            collapsed: collapsed,
            onTap: () => onTabSelected(3),
          ),
          _SidebarItem(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            active: currentIndex == 4,
            collapsed: collapsed,
            onTap: () => onTabSelected(4),
          ),
          const SizedBox(height: 16),

          // Secondary Feature Links & App Utilities
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _SidebarItem(
                    label: 'Timetable',
                    icon: Icons.calendar_view_week_rounded,
                    active: false,
                    collapsed: collapsed,
                    onTap: () => context.push('/timetable'),
                  ),
                  _SidebarItem(
                    label: 'Sticky Notes',
                    icon: Icons.note_alt_outlined,
                    active: false,
                    collapsed: collapsed,
                    onTap: () => context.push('/notes'),
                  ),
                  _SidebarItem(
                    label: 'Export Data',
                    icon: Icons.download_outlined,
                    active: false,
                    collapsed: collapsed,
                    onTap: () => ref
                        .read(settingsControllerProvider.notifier)
                        .exportCsv(),
                  ),
                  const Divider(height: 20),
                  _SidebarItem(
                    label: isDark ? 'Light Mode' : 'Dark Mode',
                    icon: isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    active: false,
                    collapsed: collapsed,
                    onTap: () =>
                        ref.read(themeModeProvider.notifier).toggleTheme(),
                  ),
                  _SidebarItem(
                    label: 'Support Developer',
                    icon: Icons.coffee_outlined,
                    active: false,
                    collapsed: collapsed,
                    onTap: () => showSupportDeveloperDialog(context),
                  ),
                  _SidebarItem(
                    label: "What's New",
                    icon: Icons.auto_awesome_outlined,
                    active: false,
                    collapsed: collapsed,
                    onTap: () => showWhatsNewDialog(context),
                  ),
                  _SidebarItem(
                    label: 'Send Feedback',
                    icon: Icons.mail_outline_rounded,
                    active: false,
                    collapsed: collapsed,
                    onTap: () => sendAppFeedback(context),
                  ),
                  _SidebarItem(
                    label: 'Share App',
                    icon: Icons.share_outlined,
                    active: false,
                    collapsed: collapsed,
                    onTap: shareAttendanceApp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = active
        ? AppColors.inkGreen
        : (isDark ? AppColors.mutedDark : AppColors.mutedLight);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 14 : 20,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.inkGreenSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              if (!collapsed) ...[
                const SizedBox(width: 16),
                Text(
                  label,
                  style: AppTypography.bodyLarge(
                    color,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
