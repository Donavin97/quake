import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/time_window.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
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
                    onChanged: (value) {
                      settings.setNotificationsEnabled(value);
                      if (value) {
                        notificationService.updateSubscriptions(
                          latitude:
                              locationProvider.currentPosition?.latitude ?? 0,
                          longitude:
                              locationProvider.currentPosition?.longitude ?? 0,
                          radius: settings.radius,
                          magnitude: settings.minMagnitude,
                        );
                      } else {
                        notificationService.updateSubscriptions(
                          latitude: 0,
                          longitude: 0,
                          radius: -1,
                          magnitude: -1,
                        );
                      }
                    }),
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
                    label:
                        'Magnitude ${settings.minMagnitude.toString()}${settings.minMagnitude == 10 ? '' : '+'}',
                    onChanged: (value) {
                      settings.setMinMagnitude(value.round());
                    },
                    onChangeEnd: (value) {
                      notificationService.updateSubscriptions(
                        latitude:
                            locationProvider.currentPosition?.latitude ?? 0,
                        longitude:
                            locationProvider.currentPosition?.longitude ?? 0,
                        radius: settings.radius,
                        magnitude: value.round(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Notification Radius: ${settings.radius.toStringAsFixed(2)} km',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Slider(
                    value: log(settings.radius + 1) / log(1001),
                    divisions: 100,
                    label: settings.radius.round().toString(),
                    onChanged: (value) {
                      final radius = pow(1001, value) - 1;
                      settings.setRadius(radius.toDouble());
                    },
                    onChangeEnd: (value) {
                      final radius = pow(1001, value) - 1;
                      notificationService.updateSubscriptions(
                        latitude:
                            locationProvider.currentPosition?.latitude ?? 0,
                        longitude:
                            locationProvider.currentPosition?.longitude ?? 0,
                        radius: radius.toDouble(),
                        magnitude: settings.minMagnitude,
                      );
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
