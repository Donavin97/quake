import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  late int _minMagnitude;
  late double _radius;
  late String _earthquakeProvider;

  // New variables for quiet hours and emergency override
  late bool _quietHoursEnabled;
  late TimeOfDay _quietHoursStart;
  late TimeOfDay _quietHoursEnd;
  late List<int> _quietHoursDays;
  late double _emergencyMagnitudeThreshold;
  late double _emergencyRadius;

  // New variables for notification overrides
  late double _globalMinMagnitudeOverrideQuietHours;
  late bool _alwaysNotifyRadiusEnabled;
  late double _alwaysNotifyRadiusValue;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _themeMode = settings.themeMode;
    _timeWindow = settings.timeWindow;
    _notificationsEnabled = settings.notificationsEnabled;
    _minMagnitude = settings.minMagnitude;
    _radius = settings.radius;
    _earthquakeProvider = settings.earthquakeProvider;

    // Initialize new quiet hours and emergency override variables
    _quietHoursEnabled = settings.quietHoursEnabled;
    _quietHoursStart = TimeOfDay(hour: settings.quietHoursStart[0], minute: settings.quietHoursStart[1]);
    _quietHoursEnd = TimeOfDay(hour: settings.quietHoursEnd[0], minute: settings.quietHoursEnd[1]);
    _quietHoursDays = List.from(settings.quietHoursDays); // Create a mutable copy
    _emergencyMagnitudeThreshold = settings.emergencyMagnitudeThreshold;
    _emergencyRadius = settings.emergencyRadius;

    // Initialize new notification override variables
    _globalMinMagnitudeOverrideQuietHours = settings.globalMinMagnitudeOverrideQuietHours;
    _alwaysNotifyRadiusEnabled = settings.alwaysNotifyRadiusEnabled;
    _alwaysNotifyRadiusValue = settings.alwaysNotifyRadiusValue;
  }

  void _applySettings() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setThemeMode(_themeMode);
    settings.setTimeWindow(_timeWindow);
    settings.setNotificationsEnabled(_notificationsEnabled);
    settings.setMinMagnitude(_minMagnitude);
    settings.setRadius(_radius);
    settings.setEarthquakeProvider(_earthquakeProvider);

    // Apply new quiet hours and emergency override settings
    settings.setQuietHoursEnabled(_quietHoursEnabled);
    settings.setQuietHoursStart([_quietHoursStart.hour, _quietHoursStart.minute]);
    settings.setQuietHoursEnd([_quietHoursEnd.hour, _quietHoursEnd.minute]);
    settings.setQuietHoursDays(_quietHoursDays);
    settings.setEmergencyMagnitudeThreshold(_emergencyMagnitudeThreshold);
    settings.setEmergencyRadius(_emergencyRadius);

    // Apply new notification override settings
    settings.setGlobalMinMagnitudeOverrideQuietHours(_globalMinMagnitudeOverrideQuietHours);
    settings.setAlwaysNotifyRadiusEnabled(_alwaysNotifyRadiusEnabled);
    settings.setAlwaysNotifyRadiusValue(_alwaysNotifyRadiusValue);

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
        child: Column(
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
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Enable Quiet Hours'),
              value: _quietHoursEnabled,
              onChanged: (value) {
                setState(() {
                  _quietHoursEnabled = value;
                });
              },
            ),
            if (_quietHoursEnabled)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Quiet Hours',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ListTile(
                    title: const Text('Start Time'),
                    trailing: Text(_quietHoursStart.format(context)),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: _quietHoursStart,
                      );
                      if (picked != null && picked != _quietHoursStart) {
                        setState(() {
                          _quietHoursStart = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Time'),
                    trailing: Text(_quietHoursEnd.format(context)),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: _quietHoursEnd,
                      );
                      if (picked != null && picked != _quietHoursEnd) {
                        setState(() {
                          _quietHoursEnd = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Quiet Days',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  // Day selection (checkboxes)
                  Wrap(
                    spacing: 8.0,
                    children: List.generate(7, (index) {
                      final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                      final isSelected = _quietHoursDays.contains(index);
                      return FilterChip(
                        label: Text(dayNames[index]),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _quietHoursDays.add(index);
                            } else {
                              _quietHoursDays.remove(index);
                            }
                            _quietHoursDays.sort(); // Keep sorted for consistency
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Emergency Override (during Quiet Hours)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text('Min Magnitude: ${_emergencyMagnitudeThreshold.toStringAsFixed(1)}'),
                  Slider(
                    value: _emergencyMagnitudeThreshold,
                    max: 10,
                    divisions: 10,
                    label: _emergencyMagnitudeThreshold.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _emergencyMagnitudeThreshold = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Emergency Radius: ${_emergencyRadius.round()} km'),
                  Slider(
                    value: log(_emergencyRadius + 1) / log(20001),
                    divisions: 100,
                    label: _emergencyRadius.round().toString(),
                    onChanged: (value) {
                      final radius = pow(20001, value) - 1;
                      setState(() {
                        _emergencyRadius = radius.toDouble();
                      });
                    },
                  ),
                ],
              ),
            if (_notificationsEnabled)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text('Minimum Magnitude: ${_minMagnitude.toStringAsFixed(1)}'),
                  Slider(
                    value: _minMagnitude.toDouble(),
                    max: 10,
                    divisions: 10,
                    label: _minMagnitude.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _minMagnitude = value.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Notification Radius: ${_radius.round()} km'),
                  Slider(
                    value: log(_radius + 1) / log(20001),
                    divisions: 100,
                    label: _radius.round().toString(),
                    onChanged: (value) {
                      final radius = pow(20001, value) - 1;
                      setState(() {
                        _radius = radius.toDouble();
                      });
                    },
                  ),
                ],
              ),
            // New UI for global magnitude override and always-notify radius
            if (_notificationsEnabled) // Only show if notifications are generally enabled
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Global Override (Always Notify)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text('Min Magnitude (Global): ${_globalMinMagnitudeOverrideQuietHours.toStringAsFixed(1)}'),
                  Slider(
                    value: _globalMinMagnitudeOverrideQuietHours,
                    max: 10,
                    divisions: 10,
                    label: _globalMinMagnitudeOverrideQuietHours.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _globalMinMagnitudeOverrideQuietHours = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('Always Notify within Radius'),
                    value: _alwaysNotifyRadiusEnabled,
                    onChanged: (value) {
                      setState(() {
                        _alwaysNotifyRadiusEnabled = value;
                      });
                    },
                  ),
                  if (_alwaysNotifyRadiusEnabled)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text('Radius Value: ${_alwaysNotifyRadiusValue.round()} km'),
                        Slider(
                          value: log(_alwaysNotifyRadiusValue + 1) / log(20001),
                          divisions: 100,
                          label: _alwaysNotifyRadiusValue.round().toString(),
                          onChanged: (value) {
                            final radius = pow(20001, value) - 1;
                            setState(() {
                              _alwaysNotifyRadiusValue = radius.toDouble();
                            });
                          },
                        ),
                      ],
                    ),
                ],
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
              items: <String>['usgs', 'emsc', 'both']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.toUpperCase()),
                );
              }).toList(),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _applySettings,
                child: const Text('Apply Settings'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
