import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/providers/repository_providers.dart';
import '../../features/auth/presentation/controllers/auth_providers.dart';
import '../../features/dashboard/presentation/providers/dashboard_providers.dart';
import 'app_banner.dart';
import 'app_drawer.dart';
import 'app_header.dart';
import 'mesh_backdrop.dart';
import 'shell/shell_bottom_nav.dart';
import 'shell/shell_desktop_sidebar.dart';

/// Responsive application shell coordinating header, guest backup warning banner,
/// desktop collapsible sidebar (>= 1024px), mobile bottom nav, and scheduler bridge.
///
/// Ownership: Shared Application Shell
// ==========================================
// SHARED SHELL - Responsive Navigation Layout
// ==========================================
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
    final authState = ref.watch(authNotifierProvider);
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final streak = ref.watch(streakCountProvider).valueOrNull ?? 0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;
          final content = _ShellContent(
            navigationShell: widget.navigationShell,
            isDesktop: isDesktop,
            isGuest: authState.isGuest,
            programName: settings?.programName,
            courseName: settings?.courseName,
            streak: streak,
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            onGuestBannerTap: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          );

          if (!isDesktop) return content;

          return Row(
            children: [
              ShellDesktopSidebar(
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
          return ShellBottomNav(
            currentIndex: widget.navigationShell.currentIndex,
            onTabSelected: _onTabSelected,
          );
        },
      ),
    );
  }
}

// ==========================================
// SHARED SHELL - Content Frame & Guest Banner
// ==========================================
class _ShellContent extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final bool isDesktop;
  final bool isGuest;
  final String? programName;
  final String? courseName;
  final int streak;
  final VoidCallback onMenuPressed;
  final VoidCallback onGuestBannerTap;

  const _ShellContent({
    required this.navigationShell,
    required this.isDesktop,
    required this.isGuest,
    required this.programName,
    required this.courseName,
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
          const _NotificationSchedulersBridge(),
          Column(
            children: [
              AppHeader(
                showMenuButton: !isDesktop,
                onMenuPressed: onMenuPressed,
                programName: programName,
                courseName: courseName,
                streak: streak,
              ),
              if (isGuest)
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

// ==========================================
// SHARED SHELL - Notification Scheduler Bridge
// Isolated leaf widget preventing scheduler updates from rebuilding AppShell.
// ==========================================
class _NotificationSchedulersBridge extends ConsumerWidget {
  const _NotificationSchedulersBridge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationSchedulerProvider);
    ref.watch(dailyFlowReminderSchedulerProvider);
    ref.watch(dailyFlowRoutineSchedulerProvider);
    return const SizedBox.shrink();
  }
}
