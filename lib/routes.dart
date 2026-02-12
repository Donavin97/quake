import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/earthquake.dart';
import 'providers/disclaimer_provider.dart';
import 'providers/location_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/disclaimer_screen.dart';
import 'screens/home_screen.dart';
import 'screens/permission_screen.dart';
import 'notification_service.dart';
import 'services/services.dart';

class AppRouter {
  final DisclaimerProvider disclaimerProvider;
  final AuthService authService;
  final LocationProvider locationProvider;
  final NotificationService notificationService;

  AppRouter(this.disclaimerProvider, this.authService, this.locationProvider, this.notificationService);

  GoRouter get router {
    return GoRouter(
      initialLocation: '/disclaimer',
      refreshListenable: Listenable.merge([
        disclaimerProvider,
        authService,
        locationProvider,
        notificationService,
      ]),
      redirect: (BuildContext context, GoRouterState state) {
        final disclaimerAccepted = disclaimerProvider.disclaimerAccepted;
        final loggedIn = authService.currentUser != null;
        final permissionsGranted = locationProvider.isPermissionGranted && notificationService.isPermissionGranted;

        final onDisclaimer = state.matchedLocation == '/disclaimer';
        final onAuth = state.matchedLocation == '/auth';
        final onPermission = state.matchedLocation == '/permission';

        if (!disclaimerAccepted) {
          return onDisclaimer ? null : '/disclaimer';
        }

        if (!loggedIn) {
          return onAuth ? null : '/auth';
        }

        if (!permissionsGranted) {
          return onPermission ? null : '/permission';
        }

        if (onDisclaimer || onAuth || onPermission) {
          return '/';
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return const HomeScreen();
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'details',
              builder: (BuildContext context, GoRouterState state) {
                final earthquake = state.extra as Earthquake?;
                if (earthquake != null) {
                  return DetailScreen(earthquake: earthquake);
                } else {
                  return const Text('Error: Earthquake data not found');
                }
              },
            ),
          ],
        ),
        GoRoute(
          path: '/disclaimer',
          builder: (BuildContext context, GoRouterState state) {
            return const DisclaimerScreen();
          },
        ),
        GoRoute(
          path: '/auth',
          builder: (BuildContext context, GoRouterState state) {
            return const AuthScreen();
          },
        ),
        GoRoute(
          path: '/permission',
          builder: (BuildContext context, GoRouterState state) {
            return const PermissionScreen();
          },
        ),
      ],
    );
  }
}
