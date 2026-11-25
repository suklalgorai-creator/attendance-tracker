import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_banner.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../providers/settings_controller.dart';

/// Card managing JSON backup export, file picking, restore validation preview,
/// and commit actions.
class BackupRestoreCard extends ConsumerWidget {
  const BackupRestoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final pending = state.pendingRestore;
    final summary = pending?.summary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Backup & Restore', style: AppTypography.cardTitle(paperColor)),
          const SizedBox(height: 8),
          Text(
            'JSON backup includes daily attendance, settings, holidays, and notes. CSV exports are not complete backups.',
            style: GoogleFonts.outfit(fontSize: 13, color: mutedColor),
          ),
          const SizedBox(height: 16),
          // Quick actions button row / column
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 300;
              final exportBtn = AppButton(
                label: 'Export full backup',
                variant: AppButtonVariant.present,
                isLoading: state.isLoading && pending == null,
                isWide: isNarrow,
                onPressed: () => controller.exportBackup(),
              );

              final chooseBtn = AppButton(
                label: 'Choose backup to restore',
                variant: AppButtonVariant.ghost,
                isWide: isNarrow,
                onPressed: () => controller.chooseBackup(),
              );

              if (isNarrow) {
                return Column(
                  children: [exportBtn, const SizedBox(height: 10), chooseBtn],
                );
              }

              return Row(
                children: [
                  Expanded(child: exportBtn),
                  const SizedBox(width: 10),
                  Expanded(child: chooseBtn),
                ],
              );
            },
          ),
          // Backup error banner
          if (state.backupError != null) ...[
            const SizedBox(height: 12),
            AppBanner(
              type: AppBannerType.danger,
              child: Text(
                state.backupError!,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.penRed,
                ),
              ),
            ),
          ],
          // Success message banner
          if (state.successMessage != null) ...[
            const SizedBox(height: 12),
            AppBanner(
              type: AppBannerType.safe,
              child: Text(
                state.successMessage!,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkGreen,
                ),
              ),
            ),
          ],
          // Pending restore preview
          if (pending != null && summary != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.ruleDark : AppColors.ruleLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('\u{1F4E6}', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        'Restore preview',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: paperColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\u2022 ${summary.legacyRecordsCount + summary.attendanceRecordsCount} attendance records will be restored',
                    style: GoogleFonts.outfit(fontSize: 13, color: paperColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\u2022 ${summary.subjectsCount} subjects & ${summary.sessionsCount} scheduled sessions',
                    style: GoogleFonts.outfit(fontSize: 13, color: paperColor),
                  ),
                  if (summary.notesCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '\u2022 ${summary.notesCount} sticky notes will be restored',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: paperColor,
                      ),
                    ),
                  ],
                  if (summary.quarantinedCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${summary.quarantinedCount} invalid item(s) will remain quarantined.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.penRed,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Confirm restore',
                          variant: AppButtonVariant.present,
                          isLoading: state.isLoading,
                          onPressed: () => controller.confirmRestore(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          label: 'Cancel',
                          variant: AppButtonVariant.clear,
                          onPressed: () => controller.cancelRestore(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
