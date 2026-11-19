import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/streak_badge_tier.dart';

/// Gamification badges showcase displaying Bronze, Silver, Gold, and Platinum streak tiers.
///
/// Exact 1:1 visual parity with `react_app/src/styles/components.css` lines 129-134.
class BadgesShowcaseWidget extends StatelessWidget {
  final int currentStreak;

  const BadgesShowcaseWidget({
    super.key,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperColor = isDark ? AppColors.paperDark : AppColors.paperLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final ruleBrightColor =
        isDark ? AppColors.ruleBrightDark : AppColors.ruleBrightLight;

    final currentTier = StreakTier.fromStreak(currentStreak);
    final nextTier = currentTier.nextTier;
    final progress = StreakTier.calculateProgress(currentStreak);

    const tiers = [
      StreakTier.bronze,
      StreakTier.silver,
      StreakTier.gold,
      StreakTier.platinum,
    ];

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ruleBrightColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Streak Badges',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: paperColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '$currentStreak ${currentStreak == 1 ? 'day' : 'days'}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 4 Badges in a Row: Bronze, Silver, Gold, Platinum
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: tiers.map((tier) {
                final isUnlocked = tier.isUnlocked(currentStreak);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildBadgeItem(
                    tier: tier,
                    isUnlocked: isUnlocked,
                    paperColor: paperColor,
                    mutedColor: mutedColor,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Progress towards next tier
          if (nextTier != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor:
                    isDark ? AppColors.ruleDark : AppColors.ruleLight,
                valueColor: AlwaysStoppedAnimation<Color>(nextTier.color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${nextTier.minDays - currentStreak} more ${nextTier.minDays - currentStreak == 1 ? 'day' : 'days'} to unlock ${nextTier.name}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: nextTier.color,
                  ),
                ),
              ],
            ),
          ] else ...[
            Center(
              child: Text(
                '👑 Maximum Streak Tier Achieved!',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkGreen,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeItem({
    required StreakTier tier,
    required bool isUnlocked,
    required Color paperColor,
    required Color mutedColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 44x44 circular badge dot matching .badge-dot in CSS
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked
                ? tier.color.withValues(alpha: 0.18)
                : Colors.transparent,
            border: Border.all(
              color: isUnlocked
                  ? tier.color
                  : mutedColor.withValues(alpha: 0.3),
              width: isUnlocked ? 2.0 : 1.0,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: tier.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            tier.emoji,
            style: TextStyle(
              fontSize: 20,
              color: isUnlocked ? null : Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tier.name,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w500,
            color: isUnlocked ? paperColor : mutedColor.withValues(alpha: 0.6),
          ),
        ),
        Text(
          '${tier.minDays}d',
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isUnlocked ? tier.color : mutedColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
