import '../entities/leaderboard_entry_entity.dart';

/// Repository contract for retrieving and sorting attendance leaderboard rankings.
///
/// Ownership: Leaderboard Feature (Domain Contract)
// ==========================================
// LEADERBOARD REPOSITORY - Domain Interface
// ==========================================
abstract class LeaderboardRepository {
  /// Fetches sorted leaderboard rankings with the current user's entry identified.
  Future<List<LeaderboardEntryEntity>> getLeaderboardEntries({
    required String? currentUserId,
    required String? currentUserName,
    required double? currentUserPercent,
    required int currentUserStreak,
  });
}
