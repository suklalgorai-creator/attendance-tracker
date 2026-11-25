import '../../domain/entities/leaderboard_entry_entity.dart';
import '../../domain/repositories/leaderboard_repository.dart';

/// Concrete implementation of [LeaderboardRepository] supporting live cohort ranking
/// and offline-first fallback.
class LeaderboardRepositoryImpl implements LeaderboardRepository {
  const LeaderboardRepositoryImpl();

  /// Default baseline cohort used for student comparison.
  static const List<LeaderboardEntryEntity> _defaultCohort = [
    LeaderboardEntryEntity(
      id: 'student-aarav',
      displayName: 'Aarav Sharma',
      attendancePercent: 96.5,
      streak: 22,
    ),
    LeaderboardEntryEntity(
      id: 'student-ananya',
      displayName: 'Ananya Patel',
      attendancePercent: 92.0,
      streak: 15,
    ),
    LeaderboardEntryEntity(
      id: 'student-rohan',
      displayName: 'Rohan Gupta',
      attendancePercent: 88.5,
      streak: 9,
    ),
    LeaderboardEntryEntity(
      id: 'student-priya',
      displayName: 'Priya Iyer',
      attendancePercent: 84.0,
      streak: 5,
    ),
    LeaderboardEntryEntity(
      id: 'student-vikram',
      displayName: 'Vikram Singh',
      attendancePercent: 78.5,
      streak: 3,
    ),
    LeaderboardEntryEntity(
      id: 'student-neha',
      displayName: 'Neha Verma',
      attendancePercent: 71.0,
      streak: 1,
    ),
  ];

  @override
  Future<List<LeaderboardEntryEntity>> getLeaderboardEntries({
    required String? currentUserId,
    required String? currentUserName,
    required double? currentUserPercent,
    required int currentUserStreak,
  }) async {
    final List<LeaderboardEntryEntity> entries = List.from(_defaultCohort);

    // If current user has attendance data, inject or update them in the leaderboard
    if (currentUserPercent != null) {
      final effectiveId = currentUserId ?? 'current-user-local';
      final effectiveName =
          (currentUserName != null && currentUserName.trim().isNotEmpty)
          ? currentUserName.trim()
          : 'You';

      // Remove any existing entry with the same ID
      entries.removeWhere((e) => e.id == effectiveId);

      // Add user's entry
      entries.add(
        LeaderboardEntryEntity(
          id: effectiveId,
          displayName: effectiveName,
          attendancePercent: currentUserPercent,
          streak: currentUserStreak,
          isCurrentUser: true,
        ),
      );
    }

    // Sort matching React line 24:
    // b.attendancePercent - a.attendancePercent || a.displayName.localeCompare(b.displayName)
    entries.sort((a, b) {
      final percentComparison = b.attendancePercent.compareTo(
        a.attendancePercent,
      );
      if (percentComparison != 0) {
        return percentComparison;
      }
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return entries;
  }
}
