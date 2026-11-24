class AttendanceMetrics {
  final double percentage;
  final bool isSafe;
  final int classesCanBunk;
  final int classesNeeded;
  final String statusMessage;

  AttendanceMetrics({
    required this.percentage,
    required this.isSafe,
    required this.classesCanBunk,
    required this.classesNeeded,
    required this.statusMessage,
  });
}

class AttendanceCalculator {
  static const double _epsilon = 1e-10;

  /// Returns whether [threshold] is a usable attendance percentage.
  ///
  /// This intentionally mirrors React's `isValidThreshold`: zero, negative,
  /// NaN, and values above 100 are not meaningful targets.
  static bool isValidThreshold(double threshold) {
    return threshold.isFinite && threshold > 0 && threshold <= 100;
  }

  /// Calculates attendance percentage, or `null` when no valid classes exist.
  static double? calculateAttendance(int present, int conducted) {
    if (conducted <= 0 || present < 0 || present > conducted) return null;
    return (present / conducted) * 100.0;
  }

  /// Calculates the maximum number of future absences that preserve [threshold].
  /// Invalid or already-dangerous records return zero, matching React.
  static int calculateMaximumAbsences(
    int present,
    int conducted,
    double threshold,
  ) {
    if (!isValidThreshold(threshold)) return 0;
    final attendance = calculateAttendance(present, conducted);
    if (attendance == null || attendance < threshold) return 0;

    final maximum =
        ((present * 100.0) / threshold - conducted + _epsilon).floor();
    return maximum < 0 ? 0 : maximum;
  }

  /// Calculates the minimum consecutive present classes needed to reach a
  /// threshold. `-1` represents React's `Infinity` for a 100% target that is
  /// currently below target.
  static int calculateRequiredRecoveryClasses(
    int present,
    int conducted,
    double threshold,
  ) {
    if (!isValidThreshold(threshold)) return 0;
    final attendance = calculateAttendance(present, conducted);
    if (attendance == null || attendance >= threshold) return 0;
    if (threshold >= 100) return -1;

    final required = (((threshold * conducted) - (100.0 * present)) /
            (100.0 - threshold) -
        _epsilon).ceil();
    return required < 0 ? 0 : required;
  }

  /// Projects attendance after adding future present and absent classes.
  static double? calculateProjectedAttendance(
    int present,
    int conducted, {
    int futurePresent = 0,
    int futureAbsent = 0,
  }) {
    if (futurePresent < 0 || futureAbsent < 0) return null;
    return calculateAttendance(
      present + futurePresent,
      conducted + futurePresent + futureAbsent,
    );
  }

  static AttendanceMetrics evaluate({
    required int attended,
    required int total,
    double target = 75.0,
  }) {
    if (total == 0) {
      return AttendanceMetrics(
        percentage: 100.0,
        isSafe: true,
        classesCanBunk: 0,
        classesNeeded: 0,
        statusMessage: "No classes logged yet",
      );
    }

    final double currentPct = calculateAttendance(attended, total) ?? 0.0;
    final effectiveTarget = isValidThreshold(target) ? target : 75.0;

    if (currentPct >= effectiveTarget) {
      // Safe to bunk calculation: attended / (total + x) >= targetRatio
      final int bunkable = calculateMaximumAbsences(attended, total, effectiveTarget);
      return AttendanceMetrics(
        percentage: currentPct,
        isSafe: true,
        classesCanBunk: bunkable,
        classesNeeded: 0,
        statusMessage: bunkable > 0 
            ? "Safe Zone: Can bunk $bunkable more class${bunkable > 1 ? 'es' : ''}" 
            : "On the edge: Don't miss your next class!",
      );
    } else {
      // Needed consecutive attendance: (attended + x) / (total + x) >= targetRatio
      final int needed = calculateRequiredRecoveryClasses(attended, total, effectiveTarget);
      return AttendanceMetrics(
        percentage: currentPct,
        isSafe: false,
        classesCanBunk: 0,
        classesNeeded: needed,
        statusMessage: "Danger Zone: Must attend next $needed class${needed > 1 ? 'es' : ''} to reach ${effectiveTarget.toInt()}%",
      );
    }
  }
}
