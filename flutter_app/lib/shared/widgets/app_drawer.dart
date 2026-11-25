import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../features/settings/presentation/providers/settings_controller.dart';
import 'shell/shell_actions.dart';

/// Navigation drawer matching `react_app/src/components/DrawerMenu.jsx`.
///
/// Ownership: Shared Navigation Drawer
// ==========================================
// SHARED DRAWER - Mobile Menu & Secondary Links
// Surfaces Timetable, Leaderboard, Sticky Notes, CSV Export, theme toggle, and support.
// ==========================================
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu',
                    style: AppTypography.cardTitle(
                      paperColor,
                    ).copyWith(fontSize: 20),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: paperColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                children: [
                  _SectionHeader(
                    title: 'ADDITIONAL FEATURES',
                    color: mutedColor,
                  ),
                  _DrawerItem(
                    emoji: '📅',
                    label: 'Timetable',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/timetable');
                    },
                  ),
                  _DrawerItem(
                    emoji: '🏆',
                    label: 'Leaderboard',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/leaderboard');
                    },
                  ),
                  _DrawerItem(
                    emoji: '📝',
                    label: 'Sticky Notes',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/notes');
                    },
                  ),
                  _DrawerItem(
                    emoji: '📊',
                    label: 'Export Data (CSV)',
                    onTap: () {
                      Navigator.of(context).pop();
                      ref.read(settingsControllerProvider.notifier).exportCsv();
                    },
                  ),
                  const Divider(),
                  _SectionHeader(title: 'APP & SETTINGS', color: mutedColor),
                  _DrawerItem(
                    emoji: isDark ? '☀️' : '🌙',
                    label: isDark
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode',
                    onTap: () =>
                        ref.read(themeModeProvider.notifier).toggleTheme(),
                  ),
                  _DrawerItem(
                    emoji: '✨',
                    label: "What's New",
                    onTap: () {
                      Navigator.of(context).pop();
                      showWhatsNewDialog(context);
                    },
                  ),
                  _DrawerItem(
                    emoji: '🔗',
                    label: 'Share App',
                    onTap: () {
                      Navigator.of(context).pop();
                      shareAttendanceApp();
                    },
                  ),
                  const Divider(),
                  _SectionHeader(title: 'SUPPORT', color: mutedColor),
                  _DrawerItem(
                    emoji: '☕',
                    label: 'Support Developer',
                    onTap: () {
                      Navigator.of(context).pop();
                      showSupportDeveloperDialog(context);
                    },
                  ),
                  _DrawerItem(
                    emoji: '✉️',
                    label: 'Send Feedback',
                    onTap: () {
                      Navigator.of(context).pop();
                      sendAppFeedback(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 20)),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}
