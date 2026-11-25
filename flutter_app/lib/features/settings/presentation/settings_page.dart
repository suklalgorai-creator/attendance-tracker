import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/repository_providers.dart';
import '../domain/entities/user_settings_entity.dart';
import 'widgets/attendance_rules_card.dart';
import 'widgets/backup_restore_card.dart';
import 'widgets/danger_zone_card.dart';
import 'widgets/notifications_card.dart';
import 'widgets/personalization_card.dart';
import 'widgets/profile_card.dart';

/// Profile & Settings screen organized into clean functional sections:
/// Account & Profile, Academic & Schedule, Notifications, Backup & Data, Danger Zone.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

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
        PersonalizationCard(settings: settings),
        const SizedBox(height: AppSpacing.md),
        AttendanceRulesCard(settings: settings),
        const SizedBox(height: AppSpacing.lg),

        _SectionLabel(title: 'NOTIFICATIONS & REMINDERS', color: mutedColor),
        NotificationsCard(settings: settings),
        const SizedBox(height: AppSpacing.lg),

        _SectionLabel(title: 'BACKUP & DATA', color: mutedColor),
        BackupRestoreCard(),
        const SizedBox(height: AppSpacing.lg),

        _SectionLabel(title: 'DANGER ZONE', color: AppColors.penRed),
        const DangerZoneCard(),
      ],
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
