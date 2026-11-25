import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/providers/repository_providers.dart';
import '../../features/auth/presentation/controllers/auth_providers.dart';
import '../../features/dashboard/presentation/providers/dashboard_providers.dart';
import '../../features/settings/presentation/providers/settings_controller.dart';
import 'app_banner.dart';
import 'app_drawer.dart';
import 'app_header.dart';
import 'mesh_backdrop.dart';

/// Responsive application shell matching the React mobile and desktop layouts.
class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarCollapsed = false;

  void _onTabSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDark
        ? const Color(0xEB18181B)
        : const Color(0xEBFFFFFF);
    final borderColor = isDark
        ? AppColors.ruleBrightDark
        : AppColors.ruleBrightLight;
    final authState = ref.watch(authNotifierProvider);
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final streak = ref.watch(streakCountProvider).valueOrNull ?? 0;
    ref.watch(notificationSchedulerProvider);
    ref.watch(dailyFlowReminderSchedulerProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;
          final content = _ShellContent(
            navigationShell: widget.navigationShell,
            isDesktop: isDesktop,
            authState: authState,
            settings: settings,
            streak: streak,
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            onGuestBannerTap: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          );

          if (!isDesktop) return content;

          return Row(
            children: [
              _DesktopSidebar(
                collapsed: _sidebarCollapsed,
                currentIndex: widget.navigationShell.currentIndex,
                onCollapseToggle: () =>
                    setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                onTabSelected: _onTabSelected,
              ),
              Expanded(child: content),
            ],
          );
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024) return const SizedBox.shrink();
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
                      isActive: widget.navigationShell.currentIndex == 0,
                      onTap: () => _onTabSelected(0),
                    ),
                  ),
                  Expanded(
                    child: _NavBarItem(
                      label: 'Register',
                      icon: Icons.calendar_today_rounded,
                      isActive: widget.navigationShell.currentIndex == 1,
                      onTap: () => _onTabSelected(1),
                    ),
                  ),
                  Expanded(
                    child: _NavBarItem(
                      label: 'Leaderboard',
                      icon: Icons.emoji_events_rounded,
                      isActive: widget.navigationShell.currentIndex == 2,
                      onTap: () => _onTabSelected(2),
                    ),
                  ),
                  Expanded(
                    child: _NavBarItem(
                      label: 'Settings',
                      icon: Icons.settings_rounded,
                      isActive: widget.navigationShell.currentIndex == 3,
                      onTap: () => _onTabSelected(3),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShellContent extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final bool isDesktop;
  final dynamic authState;
  final dynamic settings;
  final int streak;
  final VoidCallback onMenuPressed;
  final VoidCallback onGuestBannerTap;

  const _ShellContent({
    required this.navigationShell,
    required this.isDesktop,
    required this.authState,
    required this.settings,
    required this.streak,
    required this.onMenuPressed,
    required this.onGuestBannerTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          const Positioned.fill(child: MeshBackdrop()),
          Column(
            children: [
              AppHeader(
                showMenuButton: !isDesktop,
                onMenuPressed: onMenuPressed,
                programName: settings?.programName,
                courseName: settings?.courseName,
                streak: streak,
              ),
              if (authState.isGuest)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? AppSpacing.xxxl : AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: AppBanner(
                    customBackgroundColor: AppColors.amber,
                    customTextColor: Colors.black,
                    message:
                        '\u26A0\uFE0F Data not backed up! Tap here to Sign in and save your attendance in the cloud.',
                    onTap: onGuestBannerTap,
                  ),
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1400 : 480,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 40 : 0,
                      ),
                      child: navigationShell,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends ConsumerWidget {
  final bool collapsed;
  final int currentIndex;
  final VoidCallback onCollapseToggle;
  final ValueChanged<int> onTabSelected;

  const _DesktopSidebar({
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
            label: 'Leaderboard',
            icon: Icons.emoji_events_outlined,
            active: currentIndex == 2,
            collapsed: collapsed,
            onTap: () => onTabSelected(2),
          ),
          _SidebarItem(
            label: 'Settings',
            icon: Icons.settings_outlined,
            active: currentIndex == 3,
            collapsed: collapsed,
            onTap: () => onTabSelected(3),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _SidebarItem(
                    label: 'DailyFlow',
                    icon: Icons.bolt_rounded,
                    active: false,
                    collapsed: collapsed,
                    onTap: () => context.push('/dailyflow'),
                  ),
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
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Support the Developer'),
                          content: const Text(
                            'Thank you for using this app! If this app helps you, please support us by sharing it with your friends.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _SidebarItem(
                    label: "What's New",
                    icon: Icons.auto_awesome_outlined,
                    active: false,
                    collapsed: collapsed,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("What's New in v2.0"),
                          content: const Text(
                            "⚡ DailyFlow Planning, Focus Timer & Reminders\n"
                            "🔐 Google Sign-In & Cloud Firestore Sync\n"
                            "📅 Integrated Attendance Register (Holiday-aware)\n"
                            "🎨 React-Parity Glassmorphism & Mesh Themes\n"
                            "📝 Markdown Sticky Notes & CSV Export",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _SidebarItem(
                    label: 'Send Feedback',
                    icon: Icons.mail_outline_rounded,
                    active: false,
                    collapsed: collapsed,
                    onTap: () async {
                      final uri = Uri(
                        scheme: 'mailto',
                        path: 'codecraftdigital.in@gmail.com',
                        queryParameters: {'subject': 'Attendance App Feedback'},
                      );
                      try {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {}
                    },
                  ),
                  _SidebarItem(
                    label: 'Share App',
                    icon: Icons.share_outlined,
                    active: false,
                    collapsed: collapsed,
                    onTap: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text:
                              'I am tracking my college attendance easily with this app!',
                          subject: 'College Attendance Tracker',
                        ),
                      );
                    },
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
