import '../../domain/entities/user_settings_entity.dart';

/// Data model for UserSettings serialization, extending UserSettingsEntity.
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
    };
  }
}
