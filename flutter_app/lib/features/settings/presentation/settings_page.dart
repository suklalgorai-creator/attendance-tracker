import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/repository_providers.dart';
import '../domain/entities/user_settings_entity.dart';
import 'widgets/attendance_rules_card.dart';
import 'widgets/backup_restore_card.dart';
import 'widgets/danger_zone_card.dart';
import 'widgets/notifications_card.dart';
import 'widgets/personalization_card.dart';
import 'widgets/profile_card.dart';

/// Complete Settings Page replicating 1:1 React SettingsPage.jsx.
/// Assembles Profile, Personalization, Attendance Rules, Notifications,
/// Backup & Restore, and Danger Zone.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final settings = settingsAsync.valueOrNull ?? const UserSettingsEntity();

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      children: [
        ProfileCard(settings: settings),
        const SizedBox(height: AppSpacing.md),
        PersonalizationCard(settings: settings),
        const SizedBox(height: AppSpacing.md),
        AttendanceRulesCard(settings: settings),
        const SizedBox(height: AppSpacing.md),
        NotificationsCard(settings: settings),
        const SizedBox(height: AppSpacing.md),
        BackupRestoreCard(),
        const SizedBox(height: AppSpacing.md),
        const DangerZoneCard(),
      ],
    );
  }
}
