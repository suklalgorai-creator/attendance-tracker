import '../entities/user_settings_entity.dart';

/// Abstract contract for User Settings & Profile operations in Domain layer.
abstract class SettingsRepository {
  Future<UserSettingsEntity> getSettings();
  Stream<UserSettingsEntity> watchSettings();
  Future<void> saveSettings(UserSettingsEntity settings);
  Future<void> resetSettings();
}
