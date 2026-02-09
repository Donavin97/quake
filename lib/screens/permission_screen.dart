
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../services/notification_service.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final notificationService = Provider.of<NotificationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
                'We need your location and notification permission to provide accurate and timely earthquake information.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await locationProvider.requestPermission();
                if (locationProvider.isPermissionGranted) {
                  await notificationService.requestPermission();
                  if (notificationService.isPermissionGranted) {
                    context.go('/');
                  }
                }
              },
              child: const Text('Grant Permissions'),
            ),
          ],
        ),
      ),
    );
  }
}
