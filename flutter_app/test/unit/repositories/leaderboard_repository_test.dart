import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/leaderboard/data/repositories/leaderboard_repository_impl.dart';

void main() {
  const repository = LeaderboardRepositoryImpl();

  group('LeaderboardRepositoryImpl Unit Tests', () {
    test('Returns default cohort sorted descending by attendance percentage', () async {
      final entries = await repository.getLeaderboardEntries(
        currentUserId: null,
        currentUserName: null,
        currentUserPercent: null,
        currentUserStreak: 0,
      );

      expect(entries, isNotEmpty);
      for (int i = 0; i < entries.length - 1; i++) {
        expect(
          entries[i].attendancePercent >= entries[i + 1].attendancePercent,
          isTrue,
        );
      }
    });

    test('Injects and ranks current user at the top when attendance is 100%', () async {
      final entries = await repository.getLeaderboardEntries(
        currentUserId: 'my-user-id',
        currentUserName: 'Super Student',
        currentUserPercent: 100.0,
        currentUserStreak: 25,
      );

      expect(entries.first.id, 'my-user-id');
      expect(entries.first.isCurrentUser, isTrue);
      expect(entries.first.attendancePercent, 100.0);
    });

    test('Injects and ranks current user in the middle when attendance is 85%', () async {
      final entries = await repository.getLeaderboardEntries(
        currentUserId: 'my-user-id',
        currentUserName: 'Mid Student',
        currentUserPercent: 85.0,
        currentUserStreak: 7,
      );

      final userIndex = entries.indexWhere((e) => e.id == 'my-user-id');
      expect(userIndex, greaterThan(0));
      expect(userIndex, lessThan(entries.length - 1));
      expect(entries[userIndex].isCurrentUser, isTrue);
      expect(entries[userIndex - 1].attendancePercent >= 85.0, isTrue);
      expect(entries[userIndex + 1].attendancePercent <= 85.0, isTrue);
    });

    test('Tie breaks alphabetically by display name when percentages are equal', () async {
      final entries = await repository.getLeaderboardEntries(
        currentUserId: 'student-z',
        currentUserName: 'Zack',
        currentUserPercent: 92.0, // Matches Ananya Patel (92.0)
        currentUserStreak: 10,
      );

      final ananyaIndex = entries.indexWhere((e) => e.displayName == 'Ananya Patel');
      final zackIndex = entries.indexWhere((e) => e.displayName == 'Zack');

      expect(ananyaIndex, lessThan(zackIndex));
    });
  });
}
