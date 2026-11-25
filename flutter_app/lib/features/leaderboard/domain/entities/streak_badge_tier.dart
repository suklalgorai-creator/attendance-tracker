import 'package:flutter/material.dart';

/// Tier classification for streak-based attendance gamification.
enum StreakTier {
  none(name: 'Starter', minDays: 0, color: Color(0xFFA1A1AA), emoji: '🌱'),
  bronze(name: 'Bronze', minDays: 3, color: Color(0xFFCD7F32), emoji: '🥉'),
  silver(name: 'Silver', minDays: 7, color: Color(0xFFE2E8F0), emoji: '🥈'),
  gold(name: 'Gold', minDays: 14, color: Color(0xFFF59E0B), emoji: '🥇'),
  platinum(
    name: 'Platinum',
    minDays: 30,
    color: Color(0xFF38BDF8),
    emoji: '💎',
  );

  final String name;
  final int minDays;
  final Color color;
  final String emoji;

  const StreakTier({
    required this.name,
    required this.minDays,
    required this.color,
    required this.emoji,
  });

  /// Derives the active [StreakTier] from a raw streak count.
  static StreakTier fromStreak(int streak) {
    if (streak >= 30) return StreakTier.platinum;
    if (streak >= 14) return StreakTier.gold;
    if (streak >= 7) return StreakTier.silver;
    if (streak >= 3) return StreakTier.bronze;
    return StreakTier.none;
  }

  /// Calculates progression towards the next tier (0.0 to 1.0).
  static double calculateProgress(int streak) {
    if (streak <= 0) return 0.0;
    if (streak < 3) return (streak / 3.0).clamp(0.0, 1.0);
    if (streak < 7) return ((streak - 3) / (7 - 3)).clamp(0.0, 1.0);
    if (streak < 14) return ((streak - 7) / (14 - 7)).clamp(0.0, 1.0);
    if (streak < 30) return ((streak - 14) / (30 - 14)).clamp(0.0, 1.0);
    return 1.0;
  }

  /// Returns the next [StreakTier] milestone, or null if maximum tier reached.
  StreakTier? get nextTier {
    switch (this) {
      case StreakTier.none:
        return StreakTier.bronze;
      case StreakTier.bronze:
        return StreakTier.silver;
      case StreakTier.silver:
        return StreakTier.gold;
      case StreakTier.gold:
        return StreakTier.platinum;
      case StreakTier.platinum:
        return null;
    }
  }

  /// Returns whether this tier is unlocked given the user's current streak.
  bool isUnlocked(int currentStreak) => currentStreak >= minDays;
}
