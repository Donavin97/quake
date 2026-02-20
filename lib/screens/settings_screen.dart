

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/time_window.dart';
import '../providers/settings_provider.dart';
import '../screens/quiet_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _themeMode;
  late TimeWindow _timeWindow;
  late bool _notificationsEnabled;
  late int _minMagnitude;
  late double _radius;
  late double _listRadius;
  late String _earthquakeProvider;



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _themeMode = settings.themeMode;
    _timeWindow = settings.timeWindow;
    _notificationsEnabled = settings.notificationsEnabled;
    _minMagnitude = settings.minMagnitude;
    _radius = settings.radius;
    _listRadius = settings.listRadius;
    _earthquakeProvider = settings.earthquakeProvider;


  }

  void _applySettings() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setThemeMode(_themeMode);
    settings.setTimeWindow(_timeWindow);
    settings.setNotificationsEnabled(_notificationsEnabled);
    settings.setMinMagnitude(_minMagnitude);
    settings.setRadius(_radius);
    settings.setListRadius(_listRadius);
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
              title: const Text('Quiet Hours & Overrides'),
              contentPadding: EdgeInsets.zero,
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const QuietSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Minimum Magnitude',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('Notify for earthquakes magnitude $_minMagnitude and above'),
            Slider(
              value: _minMagnitude.toDouble(),
              max: 9,
              divisions: 9,
              label: _minMagnitude.toString(),
              onChanged: (value) {
                setState(() {
                  _minMagnitude = value.round();
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Notification Radius',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(_radius == 0
                ? 'Global (All Earthquakes)'
                : 'Within ${_radius.round()} km'),
            Slider(
              value: _radius,
              max: 20000, // Max radius in km
              divisions: 200, // 0 to 20000 in steps of 100
              label: _radius == 0
                  ? 'Global'
                  : '${_radius.round()} km',
              onChanged: (value) {
                setState(() {
                  _radius = value;
                });
              },
            ),

            const SizedBox(height: 16),
            Text(
              'List Display Radius',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(_listRadius == 0
                ? 'Global (All Earthquakes)'
                : 'Within ${_listRadius.round()} km'),
            Slider(
              value: _listRadius,
              max: 20000, // Max radius in km
              divisions: 200, // 0 to 20000 in steps of 100
              label: _listRadius == 0
                  ? 'Global'
                  : '${_listRadius.round()} km',
              onChanged: (value) {
                setState(() {
                  _listRadius = value;
                });
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
