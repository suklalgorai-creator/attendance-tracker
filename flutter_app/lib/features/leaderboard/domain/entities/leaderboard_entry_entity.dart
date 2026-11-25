import 'package:flutter/foundation.dart';

/// Domain entity representing an individual student's leaderboard entry.
/// Matches React `LeaderboardPage.jsx` data shape.
///
/// Ownership: Leaderboard Feature (Domain Entity)
// ==========================================
// LEADERBOARD ENTITY - Ranked Student Row
// ==========================================
@immutable
class LeaderboardEntryEntity {
  final String id;
  final String displayName;
  final double attendancePercent;
  final int streak;
  final bool isCurrentUser;

  const LeaderboardEntryEntity({
    required this.id,
    required this.displayName,
    required this.attendancePercent,
    this.streak = 0,
    this.isCurrentUser = false,
  });

  LeaderboardEntryEntity copyWith({
    String? id,
    String? displayName,
    double? attendancePercent,
    int? streak,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntryEntity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      attendancePercent: attendancePercent ?? this.attendancePercent,
      streak: streak ?? this.streak,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          attendancePercent == other.attendancePercent &&
          streak == other.streak &&
          isCurrentUser == other.isCurrentUser;

  @override
  int get hashCode =>
      Object.hash(id, displayName, attendancePercent, streak, isCurrentUser);

  @override
  String toString() =>
      'LeaderboardEntryEntity(id: $id, name: $displayName, percent: $attendancePercent%, streak: $streak, isYou: $isCurrentUser)';
}
