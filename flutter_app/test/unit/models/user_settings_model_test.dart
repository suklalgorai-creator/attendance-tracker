import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/settings/data/models/user_settings_model.dart';
import 'package:flutter_app/features/settings/domain/entities/user_settings_entity.dart';

void main() {
  group('UserSettingsModel Serialization Unit Tests', () {
    test('serializes toMap with all Schema V2 settings keys', () {
      const model = UserSettingsModel(
        name: 'Alex Johnson',
        programName: 'B.Tech CSE',
        courseName: 'Semester 4',
        startDate: '2026-01-15',
        minPercent: 80.0,
        classDays: [1, 2, 3, 4, 5],
        reminderTime: '19:30',
        pushNotificationsEnabled: true,
      );

      final map = model.toMap();

      expect(map['name'], 'Alex Johnson');
      expect(map['programName'], 'B.Tech CSE');
      expect(map['courseName'], 'Semester 4');
      expect(map['startDate'], '2026-01-15');
      expect(map['minPercent'], 80.0);
      expect(map['classDays'], [1, 2, 3, 4, 5]);
      expect(map['reminderTime'], '19:30');
      expect(map['pushNotificationsEnabled'], isTrue);
    });

    test('deserializes fromMap accurately', () {
      final map = {
        'name': 'Sam',
        'programName': 'MCA',
        'courseName': 'Sem 2',
        'startDate': '2026-02-01',
        'minPercent': 75.0,
        'classDays': [1, 2, 3, 4, 5, 6],
        'reminderTime': '17:00',
        'pushNotificationsEnabled': false,
      };

      final model = UserSettingsModel.fromMap(map);

      expect(model.name, 'Sam');
      expect(model.programName, 'MCA');
      expect(model.courseName, 'Sem 2');
      expect(model.startDate, '2026-02-01');
      expect(model.minPercent, 75.0);
      expect(model.classDays, [1, 2, 3, 4, 5, 6]);
      expect(model.reminderTime, '17:00');
      expect(model.pushNotificationsEnabled, isFalse);
    });

    test('deserializes gracefully from empty map with defaults', () {
      final model = UserSettingsModel.fromMap({});

      expect(model.name, '');
      expect(model.programName, '');
      expect(model.courseName, '');
      expect(model.startDate, '');
      expect(model.minPercent, 75.0);
      expect(model.classDays, [1, 2, 3, 4, 5]);
      expect(model.reminderTime, '18:00');
      expect(model.pushNotificationsEnabled, isFalse);
    });

    test('creates model from entity via fromEntity', () {
      const entity = UserSettingsEntity(name: 'Taylor', minPercent: 85.0);

      final model = UserSettingsModel.fromEntity(entity);

      expect(model.name, 'Taylor');
      expect(model.minPercent, 85.0);
      expect(model.classDays, [1, 2, 3, 4, 5]);
    });
  });
}
