import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../providers/settings_controller.dart';

/// Danger zone card offering safe data reset with pre-wipe confirmation modal.
///
/// Ownership: Settings Feature (UI Card)
// ==========================================
// SETTINGS CARD - Destructive Data Reset
// ==========================================
class DangerZoneCard extends ConsumerWidget {
  const DangerZoneCard({super.key});

  Future<void> _showConfirmDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
        final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

        return AlertDialog(
          backgroundColor: isDark
              ? AppColors.bgPrimaryDark
              : AppColors.bgPrimaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Clear Attendance History?',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AppColors.penRed,
            ),
          ),
          content: Text(
            'Clear all attendance records and notes? A local safety backup is recommended first.',
            style: GoogleFonts.outfit(fontSize: 14, color: paperColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(color: mutedColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.penRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Clear History',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await ref
          .read(settingsControllerProvider.notifier)
          .resetAllAttendanceAndNotes();
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance history and notes cleared.',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: AppColors.penRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Danger Zone', style: AppTypography.cardTitle(AppColors.penRed)),
          const SizedBox(height: 12),
          AppButton(
            label: 'Clear attendance history',
            variant: AppButtonVariant.clear,
            isWide: true,
            onPressed: () => _showConfirmDialog(context, ref),
          ),
          const SizedBox(height: 8),
          Text(
            'This action can be undone only by restoring a backup.',
            style: GoogleFonts.outfit(fontSize: 12, color: mutedColor),
          ),
        ],
      ),
    );
  }
}
