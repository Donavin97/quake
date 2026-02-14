// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/time_window.dart';
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
                  'Theme',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.brightness_5),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.brightness_2),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (newSelection) {
                    settings.setThemeMode(newSelection.first);
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
                    settings.setTimeWindow(newSelection.first);
                  },
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  value: settings.notificationsEnabled,
                  onChanged: (value) => settings.setNotificationsEnabled(value),
                ),
                if (settings.notificationsEnabled) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Minimum Magnitude: ${settings.minMagnitude.toString()}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Slider(
                    value: settings.minMagnitude.toDouble(),
                    max: 10,
                    divisions: 10,
                    label: settings.minMagnitude.toString(),
                    onChanged: (value) {
                      settings.setMinMagnitude(value.round());
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Notification Radius (km)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Slider(
                    value: settings.radius,
                    min: 0,
                    max: 1000,
                    divisions: 100,
                    label: settings.radius.round().toString(),
                    onChanged: (value) {
                      settings.setRadius(value);
                    },
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Earthquake Provider',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                DropdownButton<String>(
                  value: settings.earthquakeProvider,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      settings.setEarthquakeProvider(newValue);
                    }
                  },
                  items: <String>['usgs', 'emsc', 'both']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.toUpperCase()),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
