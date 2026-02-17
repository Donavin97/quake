import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class QuietSettingsScreen extends StatefulWidget {
  const QuietSettingsScreen({super.key});

  @override
  State<QuietSettingsScreen> createState() => _QuietSettingsScreenState();
}

class _QuietSettingsScreenState extends State<QuietSettingsScreen> {
  late bool _quietHoursEnabled;
  late TimeOfDay _quietHoursStart;
  late TimeOfDay _quietHoursEnd;
  late List<int> _quietHoursDays;
  late double _emergencyMagnitudeThreshold;
  late double _emergencyRadius;
  late double _globalMinMagnitudeOverrideQuietHours;
  late bool _alwaysNotifyRadiusEnabled;
  late double _alwaysNotifyRadiusValue;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _quietHoursEnabled = settings.quietHoursEnabled;
    _quietHoursStart = TimeOfDay(hour: settings.quietHoursStart[0], minute: settings.quietHoursStart[1]);
    _quietHoursEnd = TimeOfDay(hour: settings.quietHoursEnd[0], minute: settings.quietHoursEnd[1]);
    _quietHoursDays = List.from(settings.quietHoursDays);
    _emergencyMagnitudeThreshold = settings.emergencyMagnitudeThreshold;
    _emergencyRadius = settings.emergencyRadius;
    _globalMinMagnitudeOverrideQuietHours = settings.globalMinMagnitudeOverrideQuietHours;
    _alwaysNotifyRadiusEnabled = settings.alwaysNotifyRadiusEnabled;
    _alwaysNotifyRadiusValue = settings.alwaysNotifyRadiusValue;
  }

  void _applyQuietSettings() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setQuietHoursEnabled(_quietHoursEnabled);
    settings.setQuietHoursStart([_quietHoursStart.hour, _quietHoursStart.minute]);
    settings.setQuietHoursEnd([_quietHoursEnd.hour, _quietHoursEnd.minute]);
    settings.setQuietHoursDays(_quietHoursDays);
    settings.setEmergencyMagnitudeThreshold(_emergencyMagnitudeThreshold);
    settings.setEmergencyRadius(_emergencyRadius);
    settings.setGlobalMinMagnitudeOverrideQuietHours(_globalMinMagnitudeOverrideQuietHours);
    settings.setAlwaysNotifyRadiusEnabled(_alwaysNotifyRadiusEnabled);
    settings.setAlwaysNotifyRadiusValue(_alwaysNotifyRadiusValue);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quiet Hours Settings Applied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiet Hours Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            _quietHoursDays.sort();
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
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _applyQuietSettings,
                child: const Text('Apply Quiet Hours Settings'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
