import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../services/services.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  Future<void> _requestPermissions(BuildContext context) async {
    final locationProvider = context.read<LocationProvider>();
    final notificationService = context.read<NotificationService>();

    await locationProvider.requestPermission();
    await notificationService.initialize();

    if (context.mounted) {
      context.go('/auth');
    }
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
                onPressed: () => _requestPermissions(context),
                child: const Text('Grant Permissions and Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
