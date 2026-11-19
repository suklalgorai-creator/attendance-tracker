import '../entities/leaderboard_entry_entity.dart';

/// Repository contract for retrieving and publishing student attendance leaderboard rankings.
abstract class LeaderboardRepository {
  /// Fetches sorted leaderboard rankings with the current user's entry identified.
  Future<List<LeaderboardEntryEntity>> getLeaderboardEntries({
    required String? currentUserId,
    required String? currentUserName,
    required double? currentUserPercent,
    required int currentUserStreak,
  });
}
