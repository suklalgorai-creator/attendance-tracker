import '../entities/user_settings_entity.dart';

/// Domain repository contract for reading, watching, and resetting user settings.
///
/// Ownership: Settings Feature (Domain Contract)
// ==========================================
// SETTINGS REPOSITORY - Domain Interface
// ==========================================
abstract class SettingsRepository {
  Future<UserSettingsEntity> getSettings();
  Stream<UserSettingsEntity> watchSettings();
  Future<void> saveSettings(UserSettingsEntity settings);
  Future<void> resetSettings();
}
