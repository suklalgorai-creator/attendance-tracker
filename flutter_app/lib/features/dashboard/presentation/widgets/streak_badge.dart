import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/streak_popup_dialog.dart';

/// Pill badge displaying attendance streak with flame emoji and amber accent.
/// Tapping opens the [StreakPopupDialog].
class StreakBadge extends StatelessWidget {
  final int streak;
  final bool showWhenZero;
  final VoidCallback? onTap;

  const StreakBadge({
    super.key,
    required this.streak,
    this.showWhenZero = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (streak <= 0 && !showWhenZero) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => showStreakDialog(context, streak: streak),
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: AppColors.amberSoft,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppColors.amber.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '$streak',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
