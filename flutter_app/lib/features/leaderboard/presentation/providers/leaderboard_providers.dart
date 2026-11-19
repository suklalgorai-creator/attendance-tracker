import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../data/repositories/leaderboard_repository_impl.dart';
import '../../domain/entities/leaderboard_entry_entity.dart';
import '../../domain/entities/streak_badge_tier.dart';
import '../../domain/repositories/leaderboard_repository.dart';

/// Provider for [LeaderboardRepository].
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return const LeaderboardRepositoryImpl();
});

/// Reactive provider fetching and sorting leaderboard entries.
final leaderboardEntriesProvider =
    FutureProvider<List<LeaderboardEntryEntity>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  final settingsAsync = ref.watch(settingsStreamProvider);
  final statsAsync = ref.watch(dashboardStatsProvider);
  final streakAsync = ref.watch(streakCountProvider);

  final user = authState.user;
  final settings = settingsAsync.valueOrNull;
  final stats = statsAsync.valueOrNull;
  final streak = streakAsync.valueOrNull ?? 0;

  final currentUserId = user?.id;
  final currentUserName = (user?.displayName != null && user!.displayName!.isNotEmpty)
      ? user.displayName
      : ((settings?.name.isNotEmpty ?? false) ? settings!.name : 'You');

  final currentUserPercent = stats?.percentage;

  return repo.getLeaderboardEntries(
    currentUserId: currentUserId,
    currentUserName: currentUserName,
    currentUserPercent: currentUserPercent,
    currentUserStreak: streak,
  );
});

/// Computes the 1-based rank of the current user in the leaderboard (0 if not in list).
final myRankProvider = Provider<int>((ref) {
  final entriesAsync = ref.watch(leaderboardEntriesProvider);
  return entriesAsync.when(
    data: (entries) {
      final index = entries.indexWhere((e) => e.isCurrentUser);
      return index >= 0 ? index + 1 : 0;
    },
    loading: () => 0,
    error: (err, stack) => 0,
  );
});

/// Computes the current user's active gamification streak tier.
final currentStreakTierProvider = Provider<StreakTier>((ref) {
  final streak = ref.watch(streakCountProvider).valueOrNull ?? 0;
  return StreakTier.fromStreak(streak);
});
