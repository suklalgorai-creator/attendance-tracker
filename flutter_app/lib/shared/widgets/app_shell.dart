import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../features/auth/presentation/controllers/auth_providers.dart';
import 'app_banner.dart';
import 'app_drawer.dart';
import 'app_header.dart';

/// App shell wrapping all primary tabs with top AppHeader and Bottom Navigation Bar,
/// replicating react_app/src/layouts/MobileLayout.jsx and AppLayout.jsx.
class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
        ? const Color(0xEB18181B) // rgba(24, 24, 27, 0.92)
        : const Color(0xEBFFFFFF); // rgba(255, 255, 255, 0.92)
    final borderColor = isDark ? AppColors.ruleBrightDark : AppColors.ruleBrightLight;

    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            // Guest Warning Banner matching react_app/src/layouts/AppLayout.jsx
            if (authState.isGuest)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: AppBanner(
                  customBackgroundColor: AppColors.amber,
                  customTextColor: Colors.black,
                  message:
                      '⚠️ Data not backed up! Tap here to Sign in and save your attendance in the cloud.',
                  onTap: () {
                    ref.read(authNotifierProvider.notifier).signOut();
                  },
                ),
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: widget.navigationShell,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBgColor,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
    final activeColor = AppColors.inkGreen;
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
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.navLabel(isActive ? activeColor : inactiveColor),
            ),
          ],
        ),
      ),
    );
  }
}
