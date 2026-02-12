import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../notification_service.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  Future<void> _requestPermissions() async {
    final locationProvider = context.read<LocationProvider>();
    final notificationService = context.read<NotificationService>();

    await locationProvider.requestPermission();
    await notificationService.requestPermissions();

    _checkPermissions();
  }

  void _checkPermissions() {
    final locationProvider = context.read<LocationProvider>();
    final notificationService = context.read<NotificationService>();

    if (locationProvider.isPermissionGranted &&
        notificationService.isPermissionGranted) {
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'We need your location and notification permission to provide accurate and timely earthquake information.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _requestPermissions,
                child: const Text('Grant Permissions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
