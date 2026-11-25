import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/leaderboard/domain/entities/streak_badge_tier.dart';

void main() {
  group('StreakTier Gamification Logic Tests', () {
    test('Maps streak count to correct tier', () {
      expect(StreakTier.fromStreak(0), StreakTier.none);
      expect(StreakTier.fromStreak(1), StreakTier.none);
      expect(StreakTier.fromStreak(2), StreakTier.none);
      expect(StreakTier.fromStreak(3), StreakTier.bronze);
      expect(StreakTier.fromStreak(6), StreakTier.bronze);
      expect(StreakTier.fromStreak(7), StreakTier.silver);
      expect(StreakTier.fromStreak(13), StreakTier.silver);
      expect(StreakTier.fromStreak(14), StreakTier.gold);
      expect(StreakTier.fromStreak(29), StreakTier.gold);
      expect(StreakTier.fromStreak(30), StreakTier.platinum);
      expect(StreakTier.fromStreak(100), StreakTier.platinum);
    });

    test('Calculates progress percentage accurately', () {
      // Guard against negative values
      expect(StreakTier.calculateProgress(-5), 0.0);

      // 0 to 3 days (Bronze target)
      expect(StreakTier.calculateProgress(0), 0.0);
      expect(StreakTier.calculateProgress(1), closeTo(0.333, 0.001));

      // 3 to 7 days (Silver target)
      expect(StreakTier.calculateProgress(3), 0.0);
      expect(StreakTier.calculateProgress(5), 0.5); // (5-3)/(7-3) = 2/4 = 0.5

      // 7 to 14 days (Gold target)
      expect(StreakTier.calculateProgress(7), 0.0);
      expect(
        StreakTier.calculateProgress(10),
        closeTo(3 / 7, 0.001),
      ); // (10-7)/(14-7) = 3/7 ≈ 0.428

      // Max tier
      expect(StreakTier.calculateProgress(30), 1.0);
      expect(StreakTier.calculateProgress(50), 1.0);
    });

    test('Identifies unlocked status correctly', () {
      expect(StreakTier.bronze.isUnlocked(2), isFalse);
      expect(StreakTier.bronze.isUnlocked(3), isTrue);
      expect(StreakTier.silver.isUnlocked(6), isFalse);
      expect(StreakTier.silver.isUnlocked(7), isTrue);
      expect(StreakTier.platinum.isUnlocked(29), isFalse);
      expect(StreakTier.platinum.isUnlocked(30), isTrue);
    });
  });
}
