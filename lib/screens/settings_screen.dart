import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/time_window.dart';
import '../providers/settings_provider.dart';
import '../providers/earthquake_provider.dart';
import '../config/app_config.dart';
import '../widgets/community_seismograph_status.dart';
import '../widgets/vibration_settings_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;
  TimeWindow _timeWindow = TimeWindow.day;
  bool _notificationsEnabled = true;
  bool _communitySeismographEnabled = false;
  String _earthquakeProviderValue = 'usgs';
  double _mapButtonScale = 1.0;
  double _smallMarkerScale = 1.0;
  bool _settingsLoaded = false;

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
    if (state == AppLifecycleState.resumed && mounted) {
      _loadSettings();
    }
  }

  void _loadSettings() {
    if (!mounted) return;
    try {
      final settings = ref.read(settingsProvider);
      
      setState(() {
        _themeMode = settings.themeMode;
        _timeWindow = settings.timeWindow;
        _notificationsEnabled = settings.userPreferences.notificationsEnabled;
        _communitySeismographEnabled = settings.userPreferences.communitySeismographEnabled;
        _earthquakeProviderValue = settings.earthquakeProvider;
        _mapButtonScale = settings.mapButtonScale;
        _smallMarkerScale = settings.smallMarkerScale;
        _settingsLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_settingsLoaded) {
      _loadSettings();
    }
  }

  void _applySettings() {
    final notifier = ref.read(settingsProvider.notifier);
    notifier.setThemeMode(_themeMode);
    notifier.setTimeWindow(_timeWindow);
    notifier.setNotificationsEnabled(_notificationsEnabled);
    notifier.setCommunitySeismographEnabled(_communitySeismographEnabled);
    notifier.setEarthquakeProvider(_earthquakeProviderValue);
    notifier.setMapButtonScale(_mapButtonScale);
    notifier.setSmallMarkerScale(_smallMarkerScale);
    
    // Refresh earthquake list after applying settings
    ref.read(earthquakeNotifierProvider.notifier).refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings Applied')),
    );
  }

  void _showVibrationSettings() {
    showDialog(
      context: context,
      builder: (context) => const VibrationSettingsDialog(),
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
            const CommunitySeismographStatus(),
            const SizedBox(height: 8),
            Text(
              'UI Customization',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.ads_click, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Map Button Scale: ${_mapButtonScale.toStringAsFixed(1)}x')),
                      ],
                    ),
                    Slider(
                      value: _mapButtonScale,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      onChanged: (val) => setState(() => _mapButtonScale = val),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.radio_button_checked, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Small Marker Scale (<3.0): ${_smallMarkerScale.toStringAsFixed(1)}x')),
                      ],
                    ),
                    Slider(
                      value: _smallMarkerScale,
                      min: 0.5,
                      max: 3.0,
                      divisions: 25,
                      onChanged: (val) => setState(() => _smallMarkerScale = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
            SwitchListTile(
              title: const Text('Community Seismograph'),
              subtitle: const Text('Help detect earthquakes by using your phone sensors while charging.'),
              contentPadding: EdgeInsets.zero,
              value: _communitySeismographEnabled,
              onChanged: (value) {
                setState(() {
                  _communitySeismographEnabled = value;
                });
              },
            ),
            if (_communitySeismographEnabled)
              ListTile(
                title: const Text('My Contributions'),
                subtitle: const Text('View your recorded seismic detections'),
                contentPadding: const EdgeInsets.only(left: 16),
                trailing: const Icon(Icons.history),
                onTap: () {
                  GoRouter.of(context).go('/settings/community_detections');
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
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Vibration Settings'),
              subtitle: const Text('Customize seismograph feedback vibrations'),
              contentPadding: EdgeInsets.zero,
              trailing: const Icon(Icons.vibration),
              onTap: _showVibrationSettings,
            ),
            const SizedBox(height: 24),
            Text(
              'Earthquake Provider',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _earthquakeProviderValue,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: OutlineInputBorder(),
                labelText: 'Data Source',
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _earthquakeProviderValue = newValue;
                  });
                }
              },
              items: <String>['usgs', 'emsc', 'sec', 'all']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.toUpperCase()),
                );
              }).toList(),
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
                final uri = Uri.parse(AppConfig.privacyPolicyUrl);
                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                  } else {
                    // Fallback or error message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open privacy policy. Please check your browser settings.')),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('Error launching privacy policy: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: Could not open link. $e')),
                    );
                  }
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
