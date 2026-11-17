import '../../domain/entities/user_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/user_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl({SettingsLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? SettingsLocalDataSourceImpl();

  @override
  Future<UserSettingsEntity> getSettings() async {
    return _localDataSource.getSettings();
  }

  @override
  Stream<UserSettingsEntity> watchSettings() {
    return _localDataSource.watchSettings();
  }

  @override
  Future<void> saveSettings(UserSettingsEntity settings) async {
    final model = UserSettingsModel.fromEntity(settings);
    await _localDataSource.saveSettings(model);
  }

  @override
  Future<void> resetSettings() async {
    await _localDataSource.resetSettings();
  }
}
