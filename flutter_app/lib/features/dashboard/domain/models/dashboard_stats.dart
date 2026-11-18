/// Domain model representing overall attendance statistics across all subjects and legacy records.
class DashboardStats {
  final int conducted;
  final int present;
  final int absent;
  final double? percentage;
  final double minPercent;
  final int canMiss;
  final int needToAttend;
  final bool isImpossible;
  final bool isSafe;
  final int unmarkedPastSessions;

  const DashboardStats({
    required this.conducted,
    required this.present,
    required this.absent,
    required this.percentage,
    required this.minPercent,
    required this.canMiss,
    required this.needToAttend,
    required this.isImpossible,
    required this.isSafe,
    this.unmarkedPastSessions = 0,
  });

  factory DashboardStats.empty({double minPercent = 75.0}) => DashboardStats(
        conducted: 0,
        present: 0,
        absent: 0,
        percentage: null,
        minPercent: minPercent,
        canMiss: 0,
        needToAttend: 0,
        isImpossible: false,
        isSafe: true,
        unmarkedPastSessions: 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardStats &&
          runtimeType == other.runtimeType &&
          conducted == other.conducted &&
          present == other.present &&
          absent == other.absent &&
          percentage == other.percentage &&
          minPercent == other.minPercent &&
          canMiss == other.canMiss &&
          needToAttend == other.needToAttend &&
          isImpossible == other.isImpossible &&
          isSafe == other.isSafe &&
          unmarkedPastSessions == other.unmarkedPastSessions;

  @override
  int get hashCode =>
      conducted.hashCode ^
      present.hashCode ^
      absent.hashCode ^
      percentage.hashCode ^
      minPercent.hashCode ^
      canMiss.hashCode ^
      needToAttend.hashCode ^
      isImpossible.hashCode ^
      isSafe.hashCode ^
      unmarkedPastSessions.hashCode;

  @override
  String toString() {
    return 'DashboardStats(conducted: $conducted, present: $present, absent: $absent, '
        'percentage: $percentage, minPercent: $minPercent, canMiss: $canMiss, '
        'needToAttend: $needToAttend, isImpossible: $isImpossible, isSafe: $isSafe, '
        'unmarkedPastSessions: $unmarkedPastSessions)';
  }
}
