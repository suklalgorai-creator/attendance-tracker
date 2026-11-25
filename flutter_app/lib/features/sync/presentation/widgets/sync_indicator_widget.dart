import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../domain/models/sync_state.dart';
import '../providers/sync_providers.dart';

/// Header status pill visualizing cloud sync progress and triggering manual flush on tap.
///
/// Ownership: Cloud Sync Feature (UI Widget)
// ==========================================
// SYNC WIDGET - Header Cloud Sync Indicator
// ==========================================
class SyncIndicatorWidget extends ConsumerWidget {
  final SyncState? overrideState;

  const SyncIndicatorWidget({super.key, this.overrideState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        overrideState ??
        ref.watch(syncStateStreamProvider).valueOrNull ??
        const SyncState(status: SyncStatus.idle);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceHoverDark
        : AppColors.surfaceHoverLight;
    final borderColor = isDark
        ? AppColors.ruleBrightDark
        : AppColors.ruleBrightLight;

    Widget iconWidget;
    String tooltip;

    switch (state.status) {
      case SyncStatus.syncing:
        iconWidget = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.amber),
          ),
        );
        tooltip = 'Syncing to cloud...';
        break;
      case SyncStatus.synced:
        iconWidget = const Icon(
          Icons.cloud_done_rounded,
          size: 18,
          color: AppColors.inkGreen,
        );
        tooltip = 'Cloud synced';
        break;
      case SyncStatus.offlineWarning:
        iconWidget = const Icon(
          Icons.cloud_off_rounded,
          size: 18,
          color: AppColors.amber,
        );
        tooltip = 'Offline - changes queued';
        break;
      case SyncStatus.error:
        iconWidget = const Icon(
          Icons.error_outline_rounded,
          size: 18,
          color: AppColors.penRed,
        );
        tooltip = 'Sync error';
        break;
      case SyncStatus.idle:
        iconWidget = Icon(
          Icons.cloud_outlined,
          size: 18,
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        );
        tooltip = 'Cloud idle';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          try {
            ref.read(cloudSyncServiceProvider).flushToCloud();
          } catch (_) {}
        },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: iconWidget,
        ),
      ),
    );
  }
}
