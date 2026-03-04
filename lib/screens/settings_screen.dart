

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:url_launcher/url_launcher.dart';

import '../models/time_window.dart';
import '../models/user_preferences.dart';
import '../providers/settings_provider.dart';
import '../providers/earthquake_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  late ThemeMode _themeMode;
  late TimeWindow _timeWindow;
  late bool _notificationsEnabled;
  late String _earthquakeProvider;
  
  // Vibration settings - initialize with defaults to prevent crashes
  int _successDuration = 50;
  int _successPattern = 1;
  int _errorDuration = 100;
  int _errorPattern = 2;
  bool _vibrationSettingsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reinitialize settings when app resumes to ensure valid state
    if (state == AppLifecycleState.resumed && mounted) {
      _loadSettings();
    }
  }

  void _loadSettings() {
    if (!mounted) return;
    // Use listen: true to ensure we rebuild when provider notifies
    final settings = Provider.of<SettingsProvider>(context);
    
    _themeMode = settings.themeMode;
    _timeWindow = settings.timeWindow;
    _notificationsEnabled = settings.notificationsEnabled;
    _earthquakeProvider = settings.earthquakeProvider;
    
    // Load vibration settings
    _successDuration = settings.successVibration.duration;
    _successPattern = settings.successVibration.pattern;
    _errorDuration = settings.errorVibration.duration;
    _errorPattern = settings.errorVibration.pattern;
    _vibrationSettingsLoaded = true;
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load settings once
    if (!_vibrationSettingsLoaded) {
      _loadSettings();
    }
  }

  void _applySettings() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setThemeMode(_themeMode);
    settings.setTimeWindow(_timeWindow);
    settings.setNotificationsEnabled(_notificationsEnabled);
    settings.setEarthquakeProvider(_earthquakeProvider);
    
    // Apply vibration settings
    settings.setSuccessVibration(VibrationSettings(
      duration: _successDuration,
      pattern: _successPattern,
    ));
    settings.setErrorVibration(VibrationSettings(
      duration: _errorDuration,
      pattern: _errorPattern,
    ));

    // Refresh earthquake list after applying settings
    Provider.of<EarthquakeProvider>(context, listen: false).refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings Applied')),
    );
  }

  void _testSuccessVibration() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.testSuccessVibration();
  }

  void _testErrorVibration() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.testErrorVibration();
  }

  void _saveSuccessVibration() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setSuccessVibration(VibrationSettings(
      duration: _successDuration,
      pattern: _successPattern,
    ));
  }

  void _saveErrorVibration() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setErrorVibration(VibrationSettings(
      duration: _errorDuration,
      pattern: _errorPattern,
    ));
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
            Semantics(
              label: 'Earthquake data provider selection',
              child: const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text(
              'Seismograph Vibration Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            // Success Vibration Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Success Vibration',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: _testSuccessVibration,
                          icon: const Icon(Icons.vibration, size: 18),
                          label: const Text('Test'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Duration slider
                    Text('Duration: ${_successDuration}ms'),
                    Slider(
                      value: _successDuration.toDouble(),
                      min: 10,
                      max: 200,
                      divisions: 19,
                      label: '${_successDuration}ms',
                      onChanged: (value) {
                        setState(() {
                          _successDuration = value.toInt();
                        });
                      },
                      onChangeEnd: (value) {
                        _saveSuccessVibration();
                      },
                    ),
                    const SizedBox(height: 8),
                    // Pattern selector
                    Text('Intensity (pulses): $_successPattern'),
                    Slider(
                      value: _successPattern.toDouble(),
                      min: 1,
                      max: 3,
                      divisions: 20, // Allow any value from 1 to 3
                      label: '$_successPattern pulse${_successPattern > 1 ? 's' : ''}',
                      onChanged: (value) {
                        setState(() {
                          _successPattern = value.round().clamp(1, 3);
                        });
                      },
                      onChangeEnd: (value) {
                        _saveSuccessVibration();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Error Vibration Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Error Vibration',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: _testErrorVibration,
                          icon: const Icon(Icons.vibration, size: 18),
                          label: const Text('Test'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Duration slider
                    Text('Duration: ${_errorDuration}ms'),
                    Slider(
                      value: _errorDuration.toDouble(),
                      min: 50,
                      max: 300,
                      divisions: 25,
                      label: '${_errorDuration}ms',
                      onChanged: (value) {
                        setState(() {
                          _errorDuration = value.toInt();
                        });
                      },
                      onChangeEnd: (value) {
                        _saveErrorVibration();
                      },
                    ),
                    const SizedBox(height: 8),
                    // Pattern selector
                    Text('Intensity (pulses): $_errorPattern'),
                    Slider(
                      value: _errorPattern.toDouble(),
                      min: 1,
                      max: 3,
                      divisions: 20, // Allow any value from 1 to 3
                      label: '$_errorPattern pulse${_errorPattern > 1 ? 's' : ''}',
                      onChanged: (value) {
                        setState(() {
                          _errorPattern = value.round().clamp(1, 3);
                        });
                      },
                      onChangeEnd: (value) {
                        _saveErrorVibration();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ListTile(
              title: const Text('Privacy Policy'),
              contentPadding: EdgeInsets.zero,
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final uri = Uri.parse('https://quakewatch-89047796-c7f3c.web.app/privacy.html');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
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
