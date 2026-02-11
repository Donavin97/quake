import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/earthquake.dart';
import 'providers/location_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/disclaimer_screen.dart';
import 'screens/home_screen.dart';
import 'screens/permission_screen.dart';
import 'notification_service.dart';
import 'services/auth_service.dart';

class AppRouter {
  final AuthService authService;

  AppRouter(this.authService);

  GoRouter get router {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authService,
      redirect: (BuildContext context, GoRouterState state) async {
        final locationProvider =
            Provider.of<LocationProvider>(context, listen: false);
        final notificationService =
            Provider.of<NotificationService>(context, listen: false);

        final prefs = await SharedPreferences.getInstance();
        final disclaimerAccepted =
            prefs.getBool('disclaimer_accepted') ?? false;
        final loggedIn = authService.currentUser != null;

        // We can't reliably check permissions here because of async nature
        // We will check them in main.dart and rely on the UI to update

        final onDisclaimer = state.matchedLocation == '/disclaimer';
        final onAuth = state.matchedLocation == '/auth';
        final onPermission = state.matchedLocation == '/permission';

        if (!disclaimerAccepted) {
          return onDisclaimer ? null : '/disclaimer';
        }

        if (!loggedIn) {
          return onAuth ? null : '/auth';
        }
        
        final permissionsGranted = locationProvider.isPermissionGranted &&
            notificationService.isPermissionGranted;

        if (!permissionsGranted) {
          return onPermission ? null : '/permission';
        }

        // If user is on any of the setup screens and they are done with setup,
        // redirect to home
        if (onDisclaimer || onAuth || onPermission) {
          return '/';
        }

        return null; // No redirect needed
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
