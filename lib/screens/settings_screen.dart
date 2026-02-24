

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter

import '../models/time_window.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _themeMode;
  late TimeWindow _timeWindow;
  late bool _notificationsEnabled;
  late String _earthquakeProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _themeMode = settings.themeMode;
    _timeWindow = settings.timeWindow;
    _notificationsEnabled = settings.notificationsEnabled;
    _earthquakeProvider = settings.earthquakeProvider;
  }

  void _applySettings() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setThemeMode(_themeMode);
    settings.setTimeWindow(_timeWindow);
    settings.setNotificationsEnabled(_notificationsEnabled);
    settings.setEarthquakeProvider(_earthquakeProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings Applied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Theme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
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
                  icon: Icon(Icons.brightness_6),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.brightness_2),
                ),
              ],
              selected: {_themeMode},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _themeMode = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Time Window for Recent Earthquakes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<TimeWindow>(
              segments: const [
                ButtonSegment(
                  value: TimeWindow.day,
                  label: Text('Day'),
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
              selected: {_timeWindow},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _timeWindow = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              contentPadding: EdgeInsets.zero,
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            ListTile(
              title: const Text('Manage Notification Profiles'),
              contentPadding: EdgeInsets.zero,
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                GoRouter.of(context).go('/settings/notification_profiles');
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Earthquake Provider',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            DropdownButton<String>(
              value: _earthquakeProvider,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _earthquakeProvider = newValue;
                  });
                }
              },
              items: <String>['usgs', 'emsc', 'sec', 'both', 'all']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.toUpperCase()),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _applySettings,
                child: const Text('Apply Settings'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
