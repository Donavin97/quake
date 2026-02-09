
import 'package:firebase_auth/firebase_auth.dart';
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

class AppRouter {
  final BuildContext context;

  AppRouter(this.context);

  GoRouter get router {
    final firebaseUser = Provider.of<User?>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    return GoRouter(
      initialLocation: '/',
      redirect: (BuildContext context, GoRouterState state) async {
        final prefs = await SharedPreferences.getInstance();
        final disclaimerAccepted = prefs.getBool('disclaimer_accepted') ?? false;
        final bool loggedIn = firebaseUser != null;
        final bool onAuth = state.matchedLocation == '/auth';
        final bool onDisclaimer = state.matchedLocation == '/disclaimer';
        final bool onPermission = state.matchedLocation == '/permission';

        if (!disclaimerAccepted) {
          return '/disclaimer';
        }

        if (onDisclaimer) {
          return '/auth';
        }

        if (!loggedIn) {
          return '/auth';
        }

        if (onAuth) {
          return '/';
        }

        final hasLocationPermission = locationProvider.isPermissionGranted;
        if (!hasLocationPermission) {
          return '/permission';
        }

        final hasNotificationPermission = notificationService.isPermissionGranted;
        if (!hasNotificationPermission) {
          return '/permission';
        }

        if (onPermission) {
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
