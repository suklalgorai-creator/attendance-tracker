import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../features/settings/presentation/providers/settings_controller.dart';

/// Navigation drawer matching react_app/src/components/DrawerMenu.jsx:
/// - ADDITIONAL FEATURES: Leaderboard, Sticky Notes, Export Data (CSV)
/// - APP & SETTINGS: Theme Toggle, What's New, Share App
/// - SUPPORT: Support Developer, Send Feedback
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
                    onTap: () {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                  ),
                  _DrawerItem(
                    emoji: '✨',
                    label: "What's New",
                    onTap: () {
                      Navigator.of(context).pop();
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
                  _DrawerItem(
                    emoji: '🔗',
                    label: 'Share App',
                    onTap: () {
                      Navigator.of(context).pop();
                      SharePlus.instance.share(
                        ShareParams(
                          text:
                              'I am tracking my college attendance easily with this app!',
                          subject: 'College Attendance Tracker',
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _SectionHeader(title: 'SUPPORT', color: mutedColor),
                  _DrawerItem(
                    emoji: '☕',
                    label: 'Support Developer',
                    onTap: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Support Developer'),
                          content: const Text(
                            'Thank you for using College Attendance Tracker!',
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
                  _DrawerItem(
                    emoji: '✉️',
                    label: 'Send Feedback',
                    onTap: () async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      Navigator.of(context).pop();
                      final uri = Uri(
                        scheme: 'mailto',
                        path: 'codecraftdigital.in@gmail.com',
                        queryParameters: {'subject': 'Attendance App Feedback'},
                      );
                      try {
                        final launched = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                        if (!launched) {
                          messenger?.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Send feedback to codecraftdigital.in@gmail.com',
                              ),
                            ),
                          );
                        }
                      } catch (_) {
                        messenger?.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Send feedback to codecraftdigital.in@gmail.com',
                            ),
                          ),
                        );
                      }
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
