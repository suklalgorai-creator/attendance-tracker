import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/core/services/database_service.dart';
import 'package:flutter_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_app/features/auth/data/models/auth_user_model.dart';

void main() {
  group('AuthLocalDataSourceImpl Integration Tests with Real Hive', () {
    late Directory tempDir;
    late Box settingsBox;
    late AuthLocalDataSourceImpl dataSource;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_auth_test_');
      Hive.init(tempDir.path);
      settingsBox = await Hive.openBox(DatabaseService.settingsBoxName);
      dataSource = AuthLocalDataSourceImpl(box: settingsBox);
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('getSavedUser returns null when no user is saved', () async {
      final user = await dataSource.getSavedUser();
      expect(user, isNull);
      expect(dataSource.getSavedUserSync(), isNull);
    });

    test('saveUser persists auth model and getSavedUser retrieves it', () async {
      const user = AuthUserModel(
        id: 'u_123',
        email: 'user123@college.edu',
        displayName: 'John College',
        isAdmin: true,
      );

      await dataSource.saveUser(user);

      final retrieved = await dataSource.getSavedUser();
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'u_123');
      expect(retrieved.email, 'user123@college.edu');
      expect(retrieved.displayName, 'John College');
      expect(retrieved.isAdmin, isTrue);

      final syncRetrieved = dataSource.getSavedUserSync();
      expect(syncRetrieved, equals(retrieved));
    });

    test('clearUser deletes auth_user and resets guest mode', () async {
      const user = AuthUserModel(id: 'u_999', email: 'test@mail.com');
      await dataSource.saveUser(user);
      await dataSource.setGuestMode(true);

      await dataSource.clearUser();

      expect(await dataSource.getSavedUser(), isNull);
      expect(await dataSource.isGuestMode(), isFalse);
    });

    test('isGuestMode and setGuestMode manage guest session flag', () async {
      expect(await dataSource.isGuestMode(), isFalse);
      expect(dataSource.isGuestModeSync(), isFalse);

      await dataSource.setGuestMode(true);
      expect(await dataSource.isGuestMode(), isTrue);
      expect(dataSource.isGuestModeSync(), isTrue);

      await dataSource.setGuestMode(false);
      expect(await dataSource.isGuestMode(), isFalse);
    });

    test('isOnboardingComplete handles explicit boolean flag', () async {
      expect(await dataSource.isOnboardingComplete(), isFalse);
      expect(dataSource.isOnboardingCompleteSync(), isFalse);

      await dataSource.setOnboardingComplete(true);
      expect(await dataSource.isOnboardingComplete(), isTrue);
      expect(dataSource.isOnboardingCompleteSync(), isTrue);

      await dataSource.setOnboardingComplete(false);
      expect(await dataSource.isOnboardingComplete(), isFalse);
    });

    test('isOnboardingComplete falls back to user_settings startDate', () async {
      expect(await dataSource.isOnboardingComplete(), isFalse);

      // Store user_settings with startDate
      await settingsBox.put('user_settings', {
        'startDate': '2026-01-15',
        'programName': 'B.Tech CSE',
      });

      expect(await dataSource.isOnboardingComplete(), isTrue);
      expect(dataSource.isOnboardingCompleteSync(), isTrue);
    });

    test('isOnboardingComplete falls back to user_settings startDate even if explicitFlag is false', () async {
      await dataSource.setOnboardingComplete(false);
      expect(await dataSource.isOnboardingComplete(), isFalse);

      await settingsBox.put('user_settings', {
        'startDate': '2026-01-15',
        'programName': 'B.Tech CSE',
      });

      expect(await dataSource.isOnboardingComplete(), isTrue);
      expect(dataSource.isOnboardingCompleteSync(), isTrue);
    });

    test('isOnboardingComplete returns false if user_settings has empty or whitespace startDate', () async {
      await dataSource.setOnboardingComplete(false);
      await settingsBox.put('user_settings', {
        'startDate': '   ',
        'programName': 'B.Tech CSE',
      });

      expect(await dataSource.isOnboardingComplete(), isFalse);
      expect(dataSource.isOnboardingCompleteSync(), isFalse);
    });
  });
}
