/// Domain entity representing user profile & attendance configuration.
/// Replicates React user settings schema.
class UserSettingsEntity {
  final String name;
  final String programName;
  final String courseName;
  final String startDate; // YYYY-MM-DD
  final double minPercent;
  final List<int> classDays; // 0 = Sun, 1 = Mon ... 6 = Sat
  final String reminderTime; // HH:mm
  final bool pushNotificationsEnabled;

  const UserSettingsEntity({
    this.name = '',
    this.programName = '',
    this.courseName = '',
    this.startDate = '',
    this.minPercent = 75.0,
    this.classDays = const [1, 2, 3, 4, 5],
    this.reminderTime = '18:00',
    this.pushNotificationsEnabled = false,
  });

  UserSettingsEntity copyWith({
    String? name,
    String? programName,
    String? courseName,
    String? startDate,
    double? minPercent,
    List<int>? classDays,
    String? reminderTime,
    bool? pushNotificationsEnabled,
  }) {
    return UserSettingsEntity(
      name: name ?? this.name,
      programName: programName ?? this.programName,
      courseName: courseName ?? this.courseName,
      startDate: startDate ?? this.startDate,
      minPercent: minPercent ?? this.minPercent,
      classDays: classDays ?? this.classDays,
      reminderTime: reminderTime ?? this.reminderTime,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsEntity &&
          name == other.name &&
          programName == other.programName &&
          courseName == other.courseName &&
          startDate == other.startDate &&
          minPercent == other.minPercent &&
          _listEquals(classDays, other.classDays) &&
          reminderTime == other.reminderTime &&
          pushNotificationsEnabled == other.pushNotificationsEnabled;

  @override
  int get hashCode =>
      name.hashCode ^
      programName.hashCode ^
      courseName.hashCode ^
      startDate.hashCode ^
      minPercent.hashCode ^
      Object.hashAll(classDays) ^
      reminderTime.hashCode ^
      pushNotificationsEnabled.hashCode;

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
