import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/auth/data/models/auth_user_model.dart';
import 'package:flutter_app/features/auth/domain/entities/auth_user_entity.dart';

void main() {
  group('AuthUserModel Serialization Unit Tests', () {
    test('serializes toMap correctly', () {
      const model = AuthUserModel(
        id: 'u_100',
        email: 'u100@college.edu',
        displayName: 'Alice Smith',
        photoUrl: 'https://photo.url',
        isAdmin: true,
        isGuest: false,
      );

      final map = model.toMap();

      expect(map['id'], 'u_100');
      expect(map['email'], 'u100@college.edu');
      expect(map['displayName'], 'Alice Smith');
      expect(map['photoUrl'], 'https://photo.url');
      expect(map['isAdmin'], isTrue);
      expect(map['isGuest'], isFalse);
    });

    test('deserializes fromMap with valid data', () {
      final map = {
        'id': 'u_200',
        'email': 'u200@college.edu',
        'displayName': 'Bob Jones',
        'photoUrl': null,
        'isAdmin': false,
        'isGuest': false,
      };

      final model = AuthUserModel.fromMap(map);

      expect(model.id, 'u_200');
      expect(model.email, 'u200@college.edu');
      expect(model.displayName, 'Bob Jones');
      expect(model.photoUrl, isNull);
      expect(model.isAdmin, isFalse);
      expect(model.isGuest, isFalse);
    });

    test('deserializes defensively from empty/incomplete map', () {
      final model = AuthUserModel.fromMap(const {});

      expect(model.id, '');
      expect(model.email, isNull);
      expect(model.displayName, isNull);
      expect(model.photoUrl, isNull);
      expect(model.isAdmin, isFalse);
      expect(model.isGuest, isFalse);
    });

    test('creates model from entity via fromEntity and guest factory', () {
      const entity = AuthUserEntity(
        id: 'ent_1',
        email: 'ent@test.com',
        displayName: 'Entity User',
        isAdmin: true,
      );

      final model = AuthUserModel.fromEntity(entity);
      expect(model.id, 'ent_1');
      expect(model.email, 'ent@test.com');
      expect(model.displayName, 'Entity User');
      expect(model.isAdmin, isTrue);

      final guestModel = AuthUserModel.guest();
      expect(guestModel.id, 'guest');
      expect(guestModel.isGuest, isTrue);
    });
  });
}
