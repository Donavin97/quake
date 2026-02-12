import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/earthquake.dart';
import 'providers/disclaimer_provider.dart';
import 'providers/location_provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/disclaimer_screen.dart';
import 'screens/home_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/setup_screen.dart';
import 'notification_service.dart';
import 'services/services.dart';

class AppRouter {
  final DisclaimerProvider disclaimerProvider;
  final AuthService authService;
  final LocationProvider locationProvider;
  final NotificationService notificationService;
  final UserProvider userProvider;

  GoRouter? _router;

  AppRouter(
    this.disclaimerProvider,
    this.authService,
    this.locationProvider,
    this.notificationService,
    this.userProvider,
  );

  GoRouter get router => _router ??= _createRouter();

  // Private method to create the GoRouter instance
  GoRouter _createRouter() {
    // Route guards are functions that check a condition and return a redirect path if needed.
    final routeGuards = [
      // 1. Check if setup is complete
      (GoRouterState state) {
        if (!userProvider.isSetupComplete && state.matchedLocation != '/setup') {
          return '/setup';
        }
        return null;
      },
      // 2. Check if the disclaimer is accepted
      (GoRouterState state) {
        if (userProvider.isSetupComplete &&
            !disclaimerProvider.disclaimerAccepted &&
            state.matchedLocation != '/disclaimer') {
          return '/disclaimer';
        }
        return null;
      },
      // 3. Check if the user is logged in
      (GoRouterState state) {
        if (userProvider.isSetupComplete &&
            disclaimerProvider.disclaimerAccepted &&
            authService.currentUser == null &&
            state.matchedLocation != '/auth') {
          return '/auth';
        }
        return null;
      },
      // 4. Check if permissions are granted
      (GoRouterState state) {
        final permissionsGranted = locationProvider.isPermissionGranted &&
            notificationService.isPermissionGranted;
        if (userProvider.isSetupComplete &&
            disclaimerProvider.disclaimerAccepted &&
            authService.currentUser != null &&
            !permissionsGranted &&
            state.matchedLocation != '/permission') {
          return '/permission';
        }
        return null;
      },
    ];

    return GoRouter(
      initialLocation: '/',
      refreshListenable: Listenable.merge([
        disclaimerProvider,
        authService,
        locationProvider,
        notificationService,
        userProvider,
      ]),
      redirect: (BuildContext context, GoRouterState state) {
        // Sequentially check all route guards.
        for (final guard in routeGuards) {
          final redirectPath = guard(state);
          if (redirectPath != null) {
            return redirectPath;
          }
        }

        // If all checks pass and the user is on a setup-related screen, redirect to home.
        final onSetupScreen = ['/setup', '/disclaimer', '/auth', '/permission']
            .contains(state.matchedLocation);

        if (userProvider.isSetupComplete &&
            disclaimerProvider.disclaimerAccepted &&
            authService.currentUser != null &&
            locationProvider.isPermissionGranted &&
            notificationService.isPermissionGranted &&
            onSetupScreen) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'details',
              builder: (context, state) {
                final earthquake = state.extra as Earthquake?;
                if (earthquake != null) {
                  return DetailScreen(earthquake: earthquake);
                }
                return const Text('Error: Earthquake data not found');
              },
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
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/permission',
          builder: (context, state) => const PermissionScreen(),
        ),
      ],
    );
  }
}
