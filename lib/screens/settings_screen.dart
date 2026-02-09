
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/time_window.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
                  min: 0,
                  max: 10,
                  divisions: 100,
                  label: settings.minMagnitude.toStringAsFixed(1),
                  onChanged: (value) {
                    settings.updateSettings(minMagnitude: value);
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Time Window',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SegmentedButton<TimeWindow>(
                  segments: const [
                    ButtonSegment(
                      value: TimeWindow.day,
                      label: Text('1 Day'),
                      icon: Icon(Icons.today),
                    ),
                    ButtonSegment(
                      value: TimeWindow.week,
                      label: Text('7 Days'),
                      icon: Icon(Icons.calendar_view_week),
                    ),
                    ButtonSegment(
                      value: TimeWindow.month,
                      label: Text('30 Days'),
                      icon: Icon(Icons.calendar_month),
                    ),
                  ],
                  selected: {settings.timeWindow},
                  onSelectionChanged: (newSelection) {
                    settings.updateSettings(timeWindow: newSelection.first);
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Notification Radius (km): ${settings.radius.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Slider(
                  value: settings.radius,
                  min: 0,
                  max: 1000,
                  divisions: 100,
                  label: settings.radius.toStringAsFixed(0),
                  onChanged: (value) {
                    settings.updateSettings(radius: value);
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    settings.loadSettingsFromFirestore();
                  },
                  child: const Text('Load Settings from Firestore'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
