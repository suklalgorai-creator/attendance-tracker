/// Domain entity representing an authenticated or guest user.
/// Replicates Firebase user and guest session semantics in the clean architecture domain layer.
class AuthUserEntity {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAdmin;
  final bool isGuest;

  const AuthUserEntity({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAdmin = false,
    this.isGuest = false,
  });

  /// Factory creating an anonymous, offline-first guest user.
  factory AuthUserEntity.guest() => const AuthUserEntity(
        id: 'guest',
        displayName: 'Guest User',
        isGuest: true,
      );

  AuthUserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAdmin,
    bool? isGuest,
  }) {
    return AuthUserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl &&
          isAdmin == other.isAdmin &&
          isGuest == other.isGuest;

  @override
  int get hashCode => Object.hash(
        id,
        email,
        displayName,
        photoUrl,
        isAdmin,
        isGuest,
      );

  @override
  String toString() {
    return 'AuthUserEntity(id: $id, email: $email, displayName: $displayName, '
        'photoUrl: $photoUrl, isAdmin: $isAdmin, isGuest: $isGuest)';
  }
}
