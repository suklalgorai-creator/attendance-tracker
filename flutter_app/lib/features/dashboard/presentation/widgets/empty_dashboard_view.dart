import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Clean placeholder view displayed when no subjects have been enrolled yet.
class EmptyDashboardView extends StatelessWidget {
  final VoidCallback? onAddSubject;

  const EmptyDashboardView({super.key, this.onAddSubject});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_outlined,
            size: 56.0,
            color: mutedColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No subjects added yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: paperColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your enrolled subjects to start logging attendance and tracking safe bunks.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: mutedColor,
              height: 1.5,
            ),
          ),
          if (onAddSubject != null) ...[
            const SizedBox(height: 24),
            AppButton.present(label: '+ Add Subject', onPressed: onAddSubject),
          ],
        ],
      ),
    );
  }
}
