import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

/// Horizontal scrollable suggestion chip selector shared between degree program
/// and semester fields on [OnboardingPage].
///
/// Ownership: Onboarding Feature
// ==========================================
// ONBOARDING - Suggestion Chips Row
// ==========================================
class OnboardingSuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  const OnboardingSuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = suggestions[index];
          return ActionChip(
            label: Text(item),
            labelStyle: AppTypography.bodySmall(
              isDark ? AppColors.mutedDark : AppColors.mutedLight,
            ),
            backgroundColor: isDark
                ? AppColors.surfaceHoverDark
                : AppColors.surfaceLight,
            side: BorderSide(
              color: isDark
                  ? AppColors.glassBorderDark
                  : AppColors.glassBorderLight,
            ),
            onPressed: () => onSelected(item),
          );
        },
      ),
    );
  }
}
