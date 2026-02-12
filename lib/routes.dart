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
import 'screens/splash_screen.dart';
import 'services/services.dart';

class AppRouter {
  final AuthService authService;
  final LocationProvider locationProvider;
  final NotificationService notificationService;
  final DisclaimerProvider disclaimerProvider;

  AppRouter(this.authService, this.locationProvider, this.notificationService,
      this.disclaimerProvider);

  GoRouter get router {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: Listenable.merge([
        authService,
        locationProvider,
        notificationService,
        disclaimerProvider,
      ]),
      redirect: (BuildContext context, GoRouterState state) {
        final disclaimerAccepted = disclaimerProvider.disclaimerAccepted;
        final loggedIn = authService.currentUser != null;
        final permissionsGranted = locationProvider.isPermissionGranted &&
            notificationService.isPermissionGranted;

        final onSplash = state.matchedLocation == '/splash';
        final onDisclaimer = state.matchedLocation == '/disclaimer';
        final onAuth = state.matchedLocation == '/auth';
        final onPermission = state.matchedLocation == '/permission';

        if (onSplash) return null;

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
            ]),
        GoRoute(
          path: '/splash',
          builder: (BuildContext context, GoRouterState state) {
            return const SplashScreen();
          },
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
