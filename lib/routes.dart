import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/earthquake.dart';
import 'providers/user_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/disclaimer_screen.dart';
import 'screens/home_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/setup_screen.dart';
import 'services/navigation_service.dart';

class AppRouter {
  final UserProvider userProvider;

  AppRouter(this.userProvider);

  GoRouter get router => GoRouter(
        navigatorKey: NavigationService.navigatorKey,
        initialLocation: NavigationService.initialRoute ?? '/',
        refreshListenable: userProvider,
        redirect: (BuildContext context, GoRouterState state) {
          final bool isSetupComplete = userProvider.isSetupComplete;
          final String location = state.matchedLocation;

          final isSetupRoute = ['/setup', '/disclaimer', '/auth', '/permission'].contains(location);

          if (isSetupComplete && isSetupRoute) {
            return '/';
          }

          if (!isSetupComplete && !isSetupRoute) {
            return '/setup';
          }

          return null;
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'details/:id',
                builder: (context, state) {
                  final earthquake = state.extra as Earthquake?;
                  if (earthquake != null) {
                    return DetailScreen(earthquake: earthquake);
                  } else {
                    final id = state.pathParameters['id']!;
                    return DetailScreen(earthquakeId: id);
                  }
                },
              ),
              GoRoute(
                path: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/setup',
            builder: (context, state) => const SetupScreen(),
          ),
          GoRoute(
            path: '/disclaimer',
            builder: (context, state) => const DisclaimerScreen(),
          ),
          GoRoute(
            path: '/auth',
            builder: (context, state) => AuthScreen(
              onLoginSuccess: () {
                context.go('/permission');
              },
            ),
          ),
          GoRoute(
            path: '/permission',
            builder: (context, state) => const PermissionScreen(),
          ),
        ],
      );
}
