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

    final double currentPct = (attended / total) * 100.0;
    final double targetRatio = target / 100.0;

    if (currentPct >= target) {
      // Safe to bunk calculation: attended / (total + x) >= targetRatio
      final int bunkable = ((attended - (targetRatio * total)) / targetRatio).floor();
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
      final int needed = (((targetRatio * total) - attended) / (1.0 - targetRatio)).ceil();
      return AttendanceMetrics(
        percentage: currentPct,
        isSafe: false,
        classesCanBunk: 0,
        classesNeeded: needed,
        statusMessage: "Danger Zone: Must attend next $needed class${needed > 1 ? 'es' : ''} to reach ${target.toInt()}%",
      );
    }
  }
}
