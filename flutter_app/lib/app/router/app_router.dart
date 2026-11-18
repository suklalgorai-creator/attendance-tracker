import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_providers.dart';
import '../../features/auth/presentation/controllers/auth_state.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/leaderboard/presentation/leaderboard_page.dart';
import '../../features/notes/presentation/notes_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/register/presentation/register_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../shared/widgets/app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'homeBranch');
final registerNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'registerBranch');
final leaderboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'leaderboardBranch');
final settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settingsBranch');

/// Listenable notifier reacting to auth and onboarding changes without rebuilding GoRouter.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (_, _) => notifyListeners(),
    );
  }

  /// Declarative redirection rules matching React AppLayout.jsx:
  /// 1. Unauthenticated & not guest -> /auth
  /// 2. Authenticated or guest & !onboardingCompleted -> /onboarding
  /// 3. Authenticated or guest & onboardingCompleted & on /auth or /onboarding -> /
  /// 4. Else allow navigation.
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authNotifierProvider);
    final loc = state.matchedLocation;

    if (authState.status == AuthStatus.loading || authState.status == AuthStatus.initial) {
      return null;
    }

    final isAuthedOrGuest = authState.isAuthenticated || authState.isGuest;

    // Rule 1: Unauthenticated and not guest -> redirect to /auth
    if (!isAuthedOrGuest) {
      return loc == '/auth' ? null : '/auth';
    }

    // Rule 2: Authenticated or guest with incomplete onboarding -> redirect to /onboarding
    if (!authState.isOnboardingComplete) {
      return loc == '/onboarding' ? null : '/onboarding';
    }

    // Rule 3: Setup is complete; leave auth/onboarding gateways to main app
    if (loc == '/auth' || loc == '/onboarding') {
      return '/';
    }

    // Rule 4: Normal navigation within the app shell
    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Declarative GoRouter configuration replicating react_app routing and guard structure.
final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: routerNotifier,
    redirect: routerNotifier.redirect,
    initialLocation: '/',
    routes: [
      // Top-level Authentication Route
      GoRoute(
        path: '/auth',
        name: 'auth',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AuthPage(),
      ),

      // Top-level Onboarding Setup Wizard Route
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingPage(),
      ),

      // Application Shell Route (Tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard (Home)
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          // Branch 1: Register
          StatefulShellBranch(
            navigatorKey: registerNavigatorKey,
            routes: [
              GoRoute(
                path: '/register',
                name: 'register',
                builder: (context, state) => const RegisterPage(),
              ),
            ],
          ),
          // Branch 2: Leaderboard
          StatefulShellBranch(
            navigatorKey: leaderboardNavigatorKey,
            routes: [
              GoRoute(
                path: '/leaderboard',
                name: 'leaderboard',
                builder: (context, state) => const LeaderboardPage(),
              ),
            ],
          ),
          // Branch 3: Settings
          StatefulShellBranch(
            navigatorKey: settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),

      // Standalone top-level route (Sticky Notes pushed over shell)
      GoRoute(
        path: '/notes',
        name: 'notes',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotesPage(),
      ),
    ],
  );
});
