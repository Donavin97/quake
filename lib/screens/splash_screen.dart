
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/location_provider.dart';
import '../services/auth_service.dart';
import '../notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // It's better to use addPostFrameCallback to ensure the context is mounted
    // and available.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = Provider.of<AuthService>(context, listen: false);
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);

      // Wait for a short period to show the splash screen, this is good for UX.
      await Future.delayed(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final disclaimerAccepted = prefs.getBool('disclaimer_accepted') ?? false;

      if (!mounted) return;

      if (!disclaimerAccepted) {
        context.go('/disclaimer');
        return;
      }

      final loggedIn = authService.currentUser != null;
      if (!loggedIn) {
        context.go('/auth');
        return;
      }

      await locationProvider.checkPermission();
      await notificationService.init(); // Assuming init also checks/requests permissions.

      if (!mounted) return;

      final permissionsGranted = locationProvider.isPermissionGranted &&
          notificationService.isPermissionGranted;

      if (!permissionsGranted) {
        context.go('/permission');
      } else {
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Initializing...'),
          ],
        ),
      ),
    );
  }
}
