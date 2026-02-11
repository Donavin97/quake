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

        if (!disclaimerAccepted) {
          // If disclaimer is not accepted, user should be on disclaimer screen.
          return location == '/disclaimer' ? null : '/disclaimer';
        }

        // If disclaimer is accepted and user is on disclaimer screen, redirect to auth.
        if (location == '/disclaimer') {
          return '/auth';
        }

        if (!loggedIn) {
          // If user is not logged in, they should be on the auth screen.
          return location == '/auth' ? null : '/auth';
        }

        // If user is logged in and on auth screen, redirect to home.
        if (location == '/auth') {
          return '/';
        }

        final hasPermissions = locationProvider.isPermissionGranted &&
            notificationService.isPermissionGranted;

        if (!hasPermissions) {
          // If permissions are not granted, user should be on permission screen.
          return location == '/permission' ? null : '/permission';
        }

        // If permissions are granted and user is on permission screen, redirect to home.
        if (location == '/permission') {
          return '/';
        }

        return null; // No redirect needed for any other case.
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
