import '../../domain/entities/auth_user_entity.dart';

/// Data model representing an authenticated or guest user with JSON serialization.
class AuthUserModel extends AuthUserEntity {
  const AuthUserModel({
    required super.id,
    super.email,
    super.displayName,
    super.photoUrl,
    super.isAdmin = false,
    super.isGuest = false,
  });

  /// Factory creating an anonymous, offline-first guest model.
  factory AuthUserModel.guest() => const AuthUserModel(
    id: 'guest',
    displayName: 'Guest User',
    isGuest: true,
  );

  /// Convert entity to data model.
  factory AuthUserModel.fromEntity(AuthUserEntity entity) {
    return AuthUserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      isAdmin: entity.isAdmin,
      isGuest: entity.isGuest,
    );
  }

  /// Deserialization from Hive / Map with defensive fallbacks.
  factory AuthUserModel.fromMap(Map<dynamic, dynamic> map) {
    return AuthUserModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString(),
      displayName: map['displayName']?.toString(),
      photoUrl: map['photoUrl']?.toString(),
      isAdmin: map['isAdmin'] == true,
      isGuest: map['isGuest'] == true,
    );
  }

  /// Serialization to persistent map format.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAdmin': isAdmin,
      'isGuest': isGuest,
    };
  }
}
