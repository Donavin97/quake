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
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        final notificationService = Provider.of<NotificationService>(context, listen: false);

        final prefs = await SharedPreferences.getInstance();
        final disclaimerAccepted = prefs.getBool('disclaimer_accepted') ?? false;
        final bool loggedIn = authService.currentUser != null;
        final String location = state.matchedLocation;

        if (!disclaimerAccepted && location != '/disclaimer') {
          return '/disclaimer';
        }

        if (disclaimerAccepted && location == '/disclaimer') {
          return '/auth';
        }

        if (!loggedIn && location != '/auth' && location != '/disclaimer') {
          return '/auth';
        }

        if (loggedIn && location == '/auth') {
          return '/';
        }

        final hasLocationPermission = locationProvider.isPermissionGranted;
        final hasNotificationPermission =
            notificationService.isPermissionGranted;

        if (loggedIn && !(hasLocationPermission && hasNotificationPermission) && location != '/permission') {
          return '/permission';
        }

        if (loggedIn && (hasLocationPermission && hasNotificationPermission) && location == '/permission') {
          return '/';
        }

        if (loggedIn && (hasLocationPermission && hasNotificationPermission) && location == '/') {
          return null;
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
                    // Handle the case where the earthquake data is missing
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
