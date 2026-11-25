import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/mesh_backdrop.dart';
import '../domain/entities/user_settings_entity.dart';
import 'widgets/attendance_rules_card.dart';
import 'widgets/backup_restore_card.dart';
import 'widgets/danger_zone_card.dart';
import 'widgets/notifications_card.dart';
import 'widgets/personalization_card.dart';
import 'widgets/profile_card.dart';

enum _ProfileSection {
  personalization(
    title: 'Personalization',
    subtitle: 'Theme, display name, degree & semester',
    icon: Icons.palette_outlined,
  ),
  attendanceRules(
    title: 'Attendance Rules',
    subtitle: 'Minimum %, class days & start date',
    icon: Icons.rule_rounded,
  ),
  notifications(
    title: 'Notifications & DailyFlow',
    subtitle: 'Attendance reminder, briefing & horizon',
    icon: Icons.notifications_active_outlined,
  ),
  backupRestore(
    title: 'Backup & Restore',
    subtitle: 'Export or restore your local data',
    icon: Icons.backup_outlined,
  ),
  dangerZone(
    title: 'Danger Zone',
    subtitle: 'Clear attendance history',
    icon: Icons.warning_amber_rounded,
    isDestructive: true,
  );

  const _ProfileSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isDestructive = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDestructive;
}

/// Profile & Settings screen with ProfileCard at the top and collapsible
/// section tiles that open dedicated detail pages.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _openSection(BuildContext context, _ProfileSection section) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProfileSectionDetailPage(section: section),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final settings = settingsAsync.valueOrNull ?? const UserSettingsEntity();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      children: [
        _SectionLabel(title: 'ACCOUNT & PROFILE', color: mutedColor),
        ProfileCard(settings: settings),
        const SizedBox(height: AppSpacing.lg),

        _SectionLabel(title: 'ACADEMIC & SCHEDULE', color: mutedColor),
        _ProfileSectionTile(
          section: _ProfileSection.personalization,
          accentColor: const Color(0xFF3B82F6),
          onTap: () => _openSection(context, _ProfileSection.personalization),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ProfileSectionTile(
          section: _ProfileSection.attendanceRules,
          accentColor: AppColors.inkGreen,
          onTap: () => _openSection(context, _ProfileSection.attendanceRules),
        ),
        const SizedBox(height: AppSpacing.lg),

        _SectionLabel(title: 'NOTIFICATIONS & REMINDERS', color: mutedColor),
        _ProfileSectionTile(
          section: _ProfileSection.notifications,
          accentColor: AppColors.amber,
          onTap: () => _openSection(context, _ProfileSection.notifications),
        ),
        const SizedBox(height: AppSpacing.lg),

        _SectionLabel(title: 'BACKUP & DATA', color: mutedColor),
        _ProfileSectionTile(
          section: _ProfileSection.backupRestore,
          accentColor: const Color(0xFF3B82F6),
          onTap: () => _openSection(context, _ProfileSection.backupRestore),
        ),
        const SizedBox(height: AppSpacing.lg),

        _SectionLabel(title: 'DANGER ZONE', color: AppColors.penRed),
        _ProfileSectionTile(
          section: _ProfileSection.dangerZone,
          accentColor: AppColors.penRed,
          onTap: () => _openSection(context, _ProfileSection.dangerZone),
        ),
      ],
    );
  }
}

class _ProfileSectionTile extends StatelessWidget {
  const _ProfileSectionTile({
    required this.section,
    required this.accentColor,
    required this.onTap,
  });

  final _ProfileSection section;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = section.isDestructive
        ? AppColors.penRed
        : (isDark ? AppColors.paperDark : AppColors.paperLight);
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(section.icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.title, style: AppTypography.cardTitle(titleColor)),
                const SizedBox(height: 2),
                Text(
                  section.subtitle,
                  style: AppTypography.bodySmall(mutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right_rounded, size: 20, color: mutedColor),
        ],
      ),
    );
  }
}

class _ProfileSectionDetailPage extends ConsumerWidget {
  const _ProfileSectionDetailPage({required this.section});

  final _ProfileSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final settings = settingsAsync.valueOrNull ?? const UserSettingsEntity();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = section.isDestructive
        ? AppColors.penRed
        : (isDark ? AppColors.paperDark : AppColors.paperLight);

    final Widget sectionWidget = switch (section) {
      _ProfileSection.personalization => PersonalizationCard(
        settings: settings,
      ),
      _ProfileSection.attendanceRules => AttendanceRulesCard(
        settings: settings,
      ),
      _ProfileSection.notifications => NotificationsCard(settings: settings),
      _ProfileSection.backupRestore => const BackupRestoreCard(),
      _ProfileSection.dangerZone => const DangerZoneCard(),
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          section.title,
          style: AppTypography.headlineSmall.copyWith(color: titleColor),
        ),
      ),
      body: Stack(
        children: [
          const MeshBackdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              children: [sectionWidget],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionLabel({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: AppTypography.eyebrow(color).copyWith(letterSpacing: 1.4),
      ),
    );
  }
}
