import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/leaderboard/presentation/leaderboard_page.dart';
import '../../features/notes/presentation/notes_page.dart';
import '../../features/register/presentation/register_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../shared/widgets/app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'homeBranch');
final registerNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'registerBranch');
final leaderboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'leaderboardBranch');
final settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settingsBranch');

/// Declarative GoRouter configuration replicating react_app routing structure.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
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
