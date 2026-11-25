import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/database_service.dart';
import '../models/user_settings_model.dart';

/// Hive local storage contract and implementation for user profile, attendance rules,
/// and DailyFlow reminder preferences (`settings_box['user_settings']`).
///
/// Ownership: Settings Feature (Data Layer)
// ==========================================
// SETTINGS DATA SOURCE - Hive Preferences Store
// ==========================================
abstract class SettingsLocalDataSource {
  Future<UserSettingsModel> getSettings();
  Stream<UserSettingsModel> watchSettings();
  Future<void> saveSettings(UserSettingsModel settings);
  Future<void> resetSettings();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final Box _box;

  SettingsLocalDataSourceImpl({Box? box})
    : _box = box ?? DatabaseService.getBox(DatabaseService.settingsBoxName);

  @override
  Future<UserSettingsModel> getSettings() async {
    try {
      final rawData = _box.get('user_settings');
      if (rawData is Map) {
        return UserSettingsModel.fromMap(Map<String, dynamic>.from(rawData));
      }
      return const UserSettingsModel();
    } catch (e) {
      throw CacheException('Failed to load user settings: $e');
    }
  }

  @override
  Stream<UserSettingsModel> watchSettings() async* {
    yield await getSettings();
    yield* _box.watch(key: 'user_settings').asyncMap((_) => getSettings());
  }

  @override
  Future<void> saveSettings(UserSettingsModel settings) async {
    try {
      await _box.put('user_settings', settings.toMap());
    } catch (e) {
      throw CacheException('Failed to save user settings: $e');
    }
  }

  @override
  Future<void> resetSettings() async {
    try {
      const defaultSettings = UserSettingsModel();
      await _box.put('user_settings', defaultSettings.toMap());
    } catch (e) {
      throw CacheException('Failed to reset user settings: $e');
    }
  }
}
