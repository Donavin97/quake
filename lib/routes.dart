import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/earthquake.dart';
import 'providers/user_provider.dart';
import 'screens/detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/notification_profiles_screen.dart'; // Import NotificationProfilesScreen
import 'screens/notification_profile_detail_screen.dart'; // Import NotificationProfileDetailScreen
import 'screens/statistics_screen.dart'; // Import StatisticsScreen
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

          final isSetupRoute = location == '/setup';

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
                    return DetailScreen(earthquakeId: Uri.decodeComponent(id));
                  }
                },
              ),
              GoRoute(
                path: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'settings/notification_profiles',
                builder: (context, state) => const NotificationProfilesScreen(),
              ),
              GoRoute(
                path: 'settings/notification_profile_detail/:id',
                builder: (context, state) {
                  final profileId = state.pathParameters['id']!;
                  // We'll retrieve the profile from the SettingsProvider in the detail screen
                  return NotificationProfileDetailScreen(profileId: profileId);
                },
              ),
              GoRoute(
                path: 'statistics',
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/setup',
            builder: (context, state) => const SetupScreen(),
          ),
        ],
      );
}
