import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/earthquake.dart';
import 'providers/user_provider.dart';
import 'screens/detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/notification_profiles_screen.dart';
import 'screens/notification_profile_detail_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/circles_screen.dart';
import 'screens/community_detections_screen.dart';
import 'services/navigation_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final userState = ref.watch(userNotifierProvider);

  return GoRouter(
    navigatorKey: NavigationService.navigatorKey,
    initialLocation: NavigationService.initialRoute ?? '/',
    // Note: We don't use refreshListenable here because we're using ref.watch
    // which will recreate the router when userState changes.
    // For a smoother experience, one could use a Listenable that bridges Riverpod.
    redirect: (BuildContext context, GoRouterState state) {
      if (!userState.initialized) {
        return null; 
      }
      final bool isSetupComplete = userState.isSetupComplete;
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
        builder: (context, state) {
          if (!userState.initialized || !userState.isSetupComplete) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return const HomeScreen();
        },
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
              return NotificationProfileDetailScreen(profileId: profileId);
            },
          ),
          GoRoute(
            path: 'statistics',
            builder: (context, state) => const StatisticsScreen(),
          ),
          GoRoute(
            path: 'circles',
            builder: (context, state) => const CirclesScreen(),
          ),
          GoRoute(
            path: 'settings/community_detections',
            builder: (context, state) => const CommunityDetectionsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),
    ],
  );
});
