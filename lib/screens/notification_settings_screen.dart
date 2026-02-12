import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minimum Magnitude: ${settings.minMagnitude.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Slider(
                  value: settings.minMagnitude,
                  max: 10,
                  divisions: 100,
                  label: settings.minMagnitude.toStringAsFixed(1),
                  onChanged: (value) {
                    settings.setMinMagnitude(value);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
