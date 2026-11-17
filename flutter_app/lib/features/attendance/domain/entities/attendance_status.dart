/// Fixed Attendance Status enum mirroring React `ATTENDANCE_STATUS`.
enum AttendanceStatus {
  present('PRESENT'),
  absent('ABSENT'),
  unmarked('UNMARKED'),
  cancelled('CANCELLED');

  final String value;
  const AttendanceStatus(this.value);

  static AttendanceStatus fromString(String? raw) {
    if (raw == null) return AttendanceStatus.unmarked;
    return switch (raw.toUpperCase().trim()) {
      'PRESENT' => AttendanceStatus.present,
      'ABSENT' => AttendanceStatus.absent,
      'CANCELLED' => AttendanceStatus.cancelled,
      _ => AttendanceStatus.unmarked,
    };
  }

  bool get isConducted => this == AttendanceStatus.present || this == AttendanceStatus.absent;
}

const String dailySubjectId = '__daily__';
