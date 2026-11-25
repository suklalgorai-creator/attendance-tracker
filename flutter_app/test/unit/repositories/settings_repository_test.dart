import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:flutter_app/features/settings/data/models/user_settings_model.dart';
import 'package:flutter_app/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';

class FakeSettingsLocalDataSource implements SettingsLocalDataSource {
  UserSettingsModel _settings = const UserSettingsModel();
  final _controller = StreamController<UserSettingsModel>.broadcast();

  void _notify() => _controller.add(_settings);

  @override
  Future<UserSettingsModel> getSettings() async => _settings;

  @override
  Stream<UserSettingsModel> watchSettings() async* {
    yield _settings;
    yield* _controller.stream;
  }

  @override
  Future<void> saveSettings(UserSettingsModel settings) async {
    _settings = settings;
    _notify();
  }

  @override
  Future<void> resetSettings() async {
    _settings = const UserSettingsModel();
    _notify();
  }
}

void main() {
  group('SettingsRepositoryImpl Unit Tests', () {
    late FakeSettingsLocalDataSource fakeDataSource;
    late SettingsRepositoryImpl repository;

    setUp(() {
      fakeDataSource = FakeSettingsLocalDataSource();
      repository = SettingsRepositoryImpl(localDataSource: fakeDataSource);
    });

    test('getSettings returns defaults initially', () async {
      final settings = await repository.getSettings();

      expect(settings.minPercent, 75.0);
      expect(settings.classDays, [1, 2, 3, 4, 5]);
      expect(settings.reminderTime, '18:00');
      expect(settings.pushNotificationsEnabled, isFalse);
    });

    test('saveSettings updates settings and persists values', () async {
      const updated = UserSettingsEntity(
        name: 'Jordan',
        programName: 'B.Sc IT',
        courseName: 'Semester 3',
        minPercent: 80.0,
        classDays: [1, 2, 3, 4],
        reminderTime: '20:00',
        pushNotificationsEnabled: true,
      );

      await repository.saveSettings(updated);
      final retrieved = await repository.getSettings();

      expect(retrieved.name, 'Jordan');
      expect(retrieved.programName, 'B.Sc IT');
      expect(retrieved.minPercent, 80.0);
      expect(retrieved.classDays, [1, 2, 3, 4]);
      expect(retrieved.reminderTime, '20:00');
      expect(retrieved.pushNotificationsEnabled, isTrue);
    });

    test('resetSettings restores default configuration', () async {
      await repository.saveSettings(
        const UserSettingsEntity(name: 'Custom User', minPercent: 90.0),
      );

      expect((await repository.getSettings()).name, 'Custom User');

      await repository.resetSettings();
      final reset = await repository.getSettings();

      expect(reset.name, '');
      expect(reset.minPercent, 75.0);
    });

    test('watchSettings emits updates on saveSettings', () async {
      const updated = UserSettingsEntity(name: 'Watcher');

      expectLater(
        repository.watchSettings(),
        emitsInOrder([const UserSettingsEntity(), updated]),
      );

      await pumpEventQueue();
      await repository.saveSettings(updated);
    });
  });
}
