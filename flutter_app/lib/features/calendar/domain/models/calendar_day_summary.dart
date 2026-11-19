import 'package:flutter/foundation.dart';

/// Represents the attendance status type of a single calendar day.
enum CalendarDayType {
  /// No attendance was recorded for this day.
  empty,

  /// Marked as an official holiday or all classes were cancelled.
  holiday,

  /// All conducted classes on this day were attended (100%).
  present,

  /// At least one class was conducted, but zero were attended (0%).
  absent,

  /// At least one class was attended, but not all conducted classes were attended.
  partial,
}

/// Domain summary representation for a single calendar day.
@immutable
class CalendarDaySummary {
  final String date; // YYYY-MM-DD
  final CalendarDayType type;
  final int held;
  final int attended;

  const CalendarDaySummary({
    required this.date,
    required this.type,
    this.held = 0,
    this.attended = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarDaySummary &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          type == other.type &&
          held == other.held &&
          attended == other.attended;

  @override
  int get hashCode => Object.hash(date, type, held, attended);

  @override
  String toString() =>
      'CalendarDaySummary(date: $date, type: $type, held: $held, attended: $attended)';
}

/// Aggregate monthly summary statistics displayed in the Calendar footer.
@immutable
class CalendarMonthSummary {
  final int held;
  final int attended;
  final int holidays;

  const CalendarMonthSummary({
    required this.held,
    required this.attended,
    required this.holidays,
  });

  const CalendarMonthSummary.empty()
      : held = 0,
        attended = 0,
        holidays = 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarMonthSummary &&
          runtimeType == other.runtimeType &&
          held == other.held &&
          attended == other.attended &&
          holidays == other.holidays;

  @override
  int get hashCode => Object.hash(held, attended, holidays);

  @override
  String toString() =>
      'CalendarMonthSummary(held: $held, attended: $attended, holidays: $holidays)';
}
