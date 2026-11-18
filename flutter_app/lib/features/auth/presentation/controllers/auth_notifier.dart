import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Riverpod StateNotifier managing the authentication and onboarding state machine.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  int _currentEpoch = 0;

  AuthNotifier(this._authRepository)
      : super(_computeInitialState(_authRepository)) {
    init();
  }

  /// Synchronously computes the immediate state from local cached storage to eliminate flashes.
  static AuthState _computeInitialState(AuthRepository repository) {
    try {
      final cachedUser = repository.getCachedCurrentUser();
      final isOnboarded = repository.isCachedOnboardingComplete();

      if (cachedUser != null) {
        if (cachedUser.isGuest) {
          return AuthState(
            status: AuthStatus.guest,
            user: cachedUser,
            isOnboardingComplete: isOnboarded,
          );
        } else {
          return AuthState(
            status: AuthStatus.authenticated,
            user: cachedUser,
            isOnboardingComplete: isOnboarded,
          );
        }
      }
      return AuthState(
        status: AuthStatus.unauthenticated,
        isOnboardingComplete: isOnboarded,
      );
    } catch (_) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Restores existing authentication or guest session from persistent storage.
  Future<void> init() async {
    final epoch = _currentEpoch;
    try {
      final user = await _authRepository.getCurrentUser();
      if (epoch != _currentEpoch) return;
      final isOnboarded = await _authRepository.isOnboardingComplete();
      if (epoch != _currentEpoch) return;

      if (user != null) {
        if (user.isGuest) {
          state = AuthState(
            status: AuthStatus.guest,
            user: user,
            isOnboardingComplete: isOnboarded,
          );
        } else {
          state = AuthState(
            status: AuthStatus.authenticated,
            user: user,
            isOnboardingComplete: isOnboarded,
          );
        }
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          isOnboardingComplete: isOnboarded,
        );
      }
    } catch (e) {
      if (epoch != _currentEpoch) return;
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  /// Authenticate with Google provider.
  Future<void> signInWithGoogle() async {
    final epoch = ++_currentEpoch;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _authRepository.signInWithGoogle();
      if (epoch != _currentEpoch) return;
      final isOnboarded = await _authRepository.isOnboardingComplete();
      if (epoch != _currentEpoch) return;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isOnboardingComplete: isOnboarded,
      );
    } catch (e) {
      if (epoch != _currentEpoch) return;
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Enter application as an offline guest user.
  Future<void> signInAsGuest() async {
    final epoch = ++_currentEpoch;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _authRepository.signInAsGuest();
      if (epoch != _currentEpoch) return;
      final isOnboarded = await _authRepository.isOnboardingComplete();
      if (epoch != _currentEpoch) return;
      state = AuthState(
        status: AuthStatus.guest,
        user: user,
        isOnboardingComplete: isOnboarded,
      );
    } catch (e) {
      if (epoch != _currentEpoch) return;
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Mark onboarding wizard as completed and allow navigation to main screens.
  Future<void> completeOnboarding() async {
    final epoch = ++_currentEpoch;
    await _authRepository.setOnboardingComplete(true);
    if (epoch != _currentEpoch) return;
    state = state.copyWith(isOnboardingComplete: true);
  }

  /// Sign out from account or guest mode and return to auth gateway.
  Future<void> signOut() async {
    final epoch = ++_currentEpoch;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _authRepository.signOut();
      if (epoch != _currentEpoch) return;
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        isOnboardingComplete: false,
      );
    } catch (e) {
      if (epoch != _currentEpoch) return;
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
