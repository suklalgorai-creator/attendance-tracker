import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/auth/domain/entities/auth_user_entity.dart';

void main() {
  group('AuthUserEntity Unit Tests', () {
    test('instantiates with custom properties and defaults', () {
      const user = AuthUserEntity(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'John Doe',
        photoUrl: 'https://example.com/pic.png',
      );

      expect(user.id, 'user_123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'John Doe');
      expect(user.photoUrl, 'https://example.com/pic.png');
      expect(user.isAdmin, isFalse);
      expect(user.isGuest, isFalse);
    });

    test('guest factory creates guest user instance', () {
      final guest = AuthUserEntity.guest();

      expect(guest.id, 'guest');
      expect(guest.displayName, 'Guest User');
      expect(guest.isGuest, isTrue);
      expect(guest.isAdmin, isFalse);
      expect(guest.email, isNull);
    });

    test('copyWith modifies individual fields', () {
      const user = AuthUserEntity(
        id: 'u1',
        email: 'u1@test.com',
        displayName: 'User One',
      );

      final updated = user.copyWith(displayName: 'Updated Name', isAdmin: true);

      expect(updated.id, 'u1');
      expect(updated.email, 'u1@test.com');
      expect(updated.displayName, 'Updated Name');
      expect(updated.isAdmin, isTrue);
    });

    test('equality and hashCode verify value equivalence', () {
      const u1 = AuthUserEntity(
        id: '123',
        email: 'test@mail.com',
        displayName: 'Sam',
      );

      const u2 = AuthUserEntity(
        id: '123',
        email: 'test@mail.com',
        displayName: 'Sam',
      );

      const u3 = AuthUserEntity(id: '456', email: 'other@mail.com');

      expect(u1, equals(u2));
      expect(u1.hashCode, equals(u2.hashCode));
      expect(u1, isNot(equals(u3)));
    });
  });
}
