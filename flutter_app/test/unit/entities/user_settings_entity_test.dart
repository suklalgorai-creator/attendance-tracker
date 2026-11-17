import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';

void main() {
  group('UserSettingsEntity Unit Tests', () {
    test('instantiates with default values matching React dataModel.js', () {
      const settings = UserSettingsEntity();

      expect(settings.name, '');
      expect(settings.programName, '');
      expect(settings.courseName, '');
      expect(settings.startDate, '');
      expect(settings.minPercent, 75.0);
      expect(settings.classDays, [1, 2, 3, 4, 5]);
      expect(settings.reminderTime, '18:00');
      expect(settings.pushNotificationsEnabled, isFalse);
    });

    test('copyWith modifies individual fields', () {
      const settings = UserSettingsEntity();

      final updated = settings.copyWith(
        name: 'Jane Doe',
        minPercent: 80.0,
        classDays: [1, 2, 3, 4],
        pushNotificationsEnabled: true,
      );

      expect(updated.name, 'Jane Doe');
      expect(updated.minPercent, 80.0);
      expect(updated.classDays, [1, 2, 3, 4]);
      expect(updated.pushNotificationsEnabled, isTrue);
      expect(updated.reminderTime, '18:00');
    });

    test('verifies equality and hashCode include classDays', () {
      const s1 = UserSettingsEntity(
        name: 'John',
        classDays: [1, 2, 3, 4, 5],
      );

      const s2 = UserSettingsEntity(
        name: 'John',
        classDays: [1, 2, 3, 4, 5],
      );

      const s3DifferentClassDays = UserSettingsEntity(
        name: 'John',
        classDays: [1, 2, 3, 4],
      );

      // Verify that identical contents evaluate to equal
      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));

      // CRITICAL: Verify that differing classDays are NOT equal
      expect(s1, isNot(equals(s3DifferentClassDays)));
      expect(s1.hashCode, isNot(equals(s3DifferentClassDays.hashCode)));
    });
  });
}
