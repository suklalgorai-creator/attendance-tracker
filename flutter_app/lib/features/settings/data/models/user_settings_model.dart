import '../../domain/entities/user_settings_entity.dart';

/// Hive Map serialization model extending [UserSettingsEntity].
///
/// Ownership: Settings Feature (Data Model)
// ==========================================
// SETTINGS MODEL - User Preferences Serialization
// ==========================================
class UserSettingsModel extends UserSettingsEntity {
  const UserSettingsModel({
    super.name,
    super.programName,
    super.courseName,
    super.startDate,
    super.minPercent,
    super.classDays,
    super.reminderTime,
    super.pushNotificationsEnabled,
    super.dailyFlowMorningTime,
    super.dailyFlowEveningTime,
    super.dailyFlowSmartRemindersEnabled,
    super.dailyFlowFollowUpsEnabled,
    super.dailyFlowPlanningHorizonDays,
  });

  factory UserSettingsModel.fromEntity(UserSettingsEntity entity) {
    return UserSettingsModel(
      name: entity.name,
      programName: entity.programName,
      courseName: entity.courseName,
      startDate: entity.startDate,
      minPercent: entity.minPercent,
      classDays: entity.classDays,
      reminderTime: entity.reminderTime,
      pushNotificationsEnabled: entity.pushNotificationsEnabled,
      dailyFlowMorningTime: entity.dailyFlowMorningTime,
      dailyFlowEveningTime: entity.dailyFlowEveningTime,
      dailyFlowSmartRemindersEnabled: entity.dailyFlowSmartRemindersEnabled,
      dailyFlowFollowUpsEnabled: entity.dailyFlowFollowUpsEnabled,
      dailyFlowPlanningHorizonDays: entity.dailyFlowPlanningHorizonDays,
    );
  }

  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    return UserSettingsModel(
      name: (map['name'] as String?)?.trim() ?? '',
      programName: (map['programName'] as String?)?.trim() ?? '',
      courseName: (map['courseName'] as String?)?.trim() ?? '',
      startDate: (map['startDate'] as String?)?.trim() ?? '',
      minPercent: (map['minPercent'] as num?)?.toDouble() ?? 75.0,
      classDays: map['classDays'] is List
          ? (map['classDays'] as List).map((e) => (e as num).toInt()).toList()
          : const [1, 2, 3, 4, 5],
      reminderTime: (map['reminderTime'] as String?)?.trim() ?? '18:00',
      pushNotificationsEnabled:
          map['pushNotificationsEnabled'] as bool? ?? false,
      dailyFlowMorningTime:
          (map['dailyFlowMorningTime'] as String?)?.trim() ?? '07:00',
      dailyFlowEveningTime:
          (map['dailyFlowEveningTime'] as String?)?.trim() ?? '22:00',
      dailyFlowSmartRemindersEnabled:
          map['dailyFlowSmartRemindersEnabled'] as bool? ?? true,
      dailyFlowFollowUpsEnabled:
          map['dailyFlowFollowUpsEnabled'] as bool? ?? true,
      dailyFlowPlanningHorizonDays:
          (map['dailyFlowPlanningHorizonDays'] as num?)?.toInt() ?? 7,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'programName': programName,
      'courseName': courseName,
      'startDate': startDate,
      'minPercent': minPercent,
      'classDays': classDays,
      'reminderTime': reminderTime,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'dailyFlowMorningTime': dailyFlowMorningTime,
      'dailyFlowEveningTime': dailyFlowEveningTime,
      'dailyFlowSmartRemindersEnabled': dailyFlowSmartRemindersEnabled,
      'dailyFlowFollowUpsEnabled': dailyFlowFollowUpsEnabled,
      'dailyFlowPlanningHorizonDays': dailyFlowPlanningHorizonDays,
    };
  }
}
