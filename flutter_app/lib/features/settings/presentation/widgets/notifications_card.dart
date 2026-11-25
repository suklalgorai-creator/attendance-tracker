import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../providers/settings_controller.dart';

/// Card managing reminder time and push notifications preferences.
class NotificationsCard extends ConsumerWidget {
  final UserSettingsEntity settings;

  const NotificationsCard({super.key, required this.settings});

  Future<void> _pickReminderTime(BuildContext context, WidgetRef ref) async {
    final current = settings.reminderTime;
    TimeOfDay initial = const TimeOfDay(hour: 18, minute: 0);
    if (current.contains(':')) {
      final parts = current.split(':');
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        initial = TimeOfDay(hour: h, minute: m);
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.inkGreen,
                    onPrimary: Colors.white,
                    surface: AppColors.bgPrimaryDark,
                    onSurface: AppColors.paperDark,
                  )
                : const ColorScheme.light(
                    primary: AppColors.inkGreen,
                    onPrimary: Colors.white,
                    surface: AppColors.bgPrimaryLight,
                    onSurface: AppColors.paperLight,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      ref
          .read(settingsControllerProvider.notifier)
          .updateReminderTime(formatted);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final borderColor = isDark
        ? AppColors.glassBorderDark
        : AppColors.glassBorderLight;
    final inputBg = isDark ? AppColors.inputBgDark : AppColors.inputBgLight;

    final isEnabled = settings.pushNotificationsEnabled;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: AppTypography.cardTitle(paperColor)),
          const SizedBox(height: 16),
          // Remind me if not marked by
          Text(
            'REMIND ME IF NOT MARKED BY',
            style: AppTypography.inputLabel(mutedColor),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickReminderTime(context, ref),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    settings.reminderTime.isNotEmpty
                        ? settings.reminderTime
                        : '18:00',
                    style: GoogleFonts.outfit(fontSize: 15, color: paperColor),
                  ),
                  Icon(Icons.access_time_rounded, size: 18, color: mutedColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Push notification status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  isEnabled ? '✅ Enabled' : 'Disabled',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? AppColors.inkGreen : mutedColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: isEnabled ? 'Disable in app' : 'Enable',
                variant: isEnabled
                    ? AppButtonVariant.ghost
                    : AppButtonVariant.present,
                onPressed: () {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .togglePushNotifications();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Disabling removes this app\u2019s token; notification permissions can also be changed in device settings.',
            style: GoogleFonts.outfit(fontSize: 12, color: mutedColor),
          ),
        ],
      ),
    );
  }
}
