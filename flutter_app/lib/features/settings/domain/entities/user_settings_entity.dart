/// Domain entity holding user profile, attendance threshold, class schedule,
/// and DailyFlow reminder configuration.
///
/// Ownership: Settings Feature (Domain Entity)
// ==========================================
// SETTINGS ENTITY - User Preferences & Rules
// ==========================================
class UserSettingsEntity {
  final String name;
  final String programName;
  final String courseName;
  final String startDate; // YYYY-MM-DD
  final double minPercent;
  final List<int> classDays; // 0 = Sun, 1 = Mon ... 6 = Sat
  final String reminderTime; // HH:mm
  final bool pushNotificationsEnabled;
  final String dailyFlowMorningTime; // HH:mm (default 07:00)
  final String dailyFlowEveningTime; // HH:mm (default 22:00)
  final bool dailyFlowSmartRemindersEnabled;
  final bool dailyFlowFollowUpsEnabled;
  final int dailyFlowPlanningHorizonDays;

  const UserSettingsEntity({
    this.name = '',
    this.programName = '',
    this.courseName = '',
    this.startDate = '',
    this.minPercent = 75.0,
    this.classDays = const [1, 2, 3, 4, 5],
    this.reminderTime = '18:00',
    this.pushNotificationsEnabled = false,
    this.dailyFlowMorningTime = '07:00',
    this.dailyFlowEveningTime = '22:00',
    this.dailyFlowSmartRemindersEnabled = true,
    this.dailyFlowFollowUpsEnabled = true,
    this.dailyFlowPlanningHorizonDays = 7,
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
    String? dailyFlowMorningTime,
    String? dailyFlowEveningTime,
    bool? dailyFlowSmartRemindersEnabled,
    bool? dailyFlowFollowUpsEnabled,
    int? dailyFlowPlanningHorizonDays,
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
      dailyFlowMorningTime: dailyFlowMorningTime ?? this.dailyFlowMorningTime,
      dailyFlowEveningTime: dailyFlowEveningTime ?? this.dailyFlowEveningTime,
      dailyFlowSmartRemindersEnabled:
          dailyFlowSmartRemindersEnabled ?? this.dailyFlowSmartRemindersEnabled,
      dailyFlowFollowUpsEnabled:
          dailyFlowFollowUpsEnabled ?? this.dailyFlowFollowUpsEnabled,
      dailyFlowPlanningHorizonDays:
          dailyFlowPlanningHorizonDays ?? this.dailyFlowPlanningHorizonDays,
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
          pushNotificationsEnabled == other.pushNotificationsEnabled &&
          dailyFlowMorningTime == other.dailyFlowMorningTime &&
          dailyFlowEveningTime == other.dailyFlowEveningTime &&
          dailyFlowSmartRemindersEnabled ==
              other.dailyFlowSmartRemindersEnabled &&
          dailyFlowFollowUpsEnabled == other.dailyFlowFollowUpsEnabled &&
          dailyFlowPlanningHorizonDays == other.dailyFlowPlanningHorizonDays;

  @override
  int get hashCode => Object.hash(
    name,
    programName,
    courseName,
    startDate,
    minPercent,
    Object.hashAll(classDays),
    reminderTime,
    pushNotificationsEnabled,
    dailyFlowMorningTime,
    dailyFlowEveningTime,
    dailyFlowSmartRemindersEnabled,
    dailyFlowFollowUpsEnabled,
    dailyFlowPlanningHorizonDays,
  );

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
