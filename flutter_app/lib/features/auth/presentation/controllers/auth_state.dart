import '../../domain/entities/auth_user_entity.dart';

/// Authentication status representation matching React app authentication lifecycle.
enum AuthStatus {
  initial,
  unauthenticated,
  authenticated,
  guest,
  loading,
  error,
}

/// State representation for authentication and initial onboarding.
class AuthState {
  final AuthStatus status;
  final AuthUserEntity? user;
  final bool isOnboardingComplete;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.isOnboardingComplete = false,
    this.errorMessage,
  });

  bool get isLoading => status == AuthStatus.loading || status == AuthStatus.initial;
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isGuest => status == AuthStatus.guest || (user?.isGuest ?? false);
  bool get isLoggedIn => isAuthenticated || isGuest;

  AuthState copyWith({
    AuthStatus? status,
    AuthUserEntity? user,
    bool? isOnboardingComplete,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          user == other.user &&
          isOnboardingComplete == other.isOnboardingComplete &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        status,
        user,
        isOnboardingComplete,
        errorMessage,
      );

  @override
  String toString() {
    return 'AuthState(status: $status, user: $user, '
        'isOnboardingComplete: $isOnboardingComplete, errorMessage: $errorMessage)';
  }
}
