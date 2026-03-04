import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../models/notification_profile.dart';
import '../providers/settings_provider.dart';
import '../providers/location_provider.dart';

class NotificationProfileDetailScreen extends StatefulWidget {
  final String profileId;

  const NotificationProfileDetailScreen({super.key, required this.profileId});

  @override
  State<NotificationProfileDetailScreen> createState() =>
      _NotificationProfileDetailScreenState();
}

class _NotificationProfileDetailScreenState
    extends State<NotificationProfileDetailScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  NotificationProfile? _profile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // Values for Sliders and Toggles
  double _minMagnitude = 4.5;
  double _radius = 0.0;
  bool _quietHoursEnabled = false;
  List<int> _quietHoursStart = [22, 0];
  List<int> _quietHoursEnd = [6, 0];
  List<int> _quietHoursDays = [0, 1, 2, 3, 4, 5, 6];
  bool _alwaysNotifyRadiusEnabled = false;
  double _alwaysNotifyRadiusValue = 0.0;
  double _emergencyMagnitudeThreshold = 5.0;
  double _emergencyRadius = 100.0;
  double _globalMinMagnitudeOverrideQuietHours = 0.0;
  String? _timezone;

  // List of common timezones for the picker
  static final List<Map<String, String>> _commonTimezones = [
    {'value': 'America/New_York', 'label': 'Eastern Time (US)'},
    {'value': 'America/Chicago', 'label': 'Central Time (US)'},
    {'value': 'America/Denver', 'label': 'Mountain Time (US)'},
    {'value': 'America/Los_Angeles', 'label': 'Pacific Time (US)'},
    {'value': 'America/Anchorage', 'label': 'Alaska Time'},
    {'value': 'Pacific/Honolulu', 'label': 'Hawaii Time'},
    {'value': 'Europe/London', 'label': 'London (GMT/BST)'},
    {'value': 'Europe/Paris', 'label': 'Central European (CET)'},
    {'value': 'Europe/Berlin', 'label': 'Berlin (CET)'},
    {'value': 'Europe/Moscow', 'label': 'Moscow (MSK)'},
    {'value': 'Africa/Johannesburg', 'label': 'South Africa (SAST)'},
    {'value': 'Asia/Dubai', 'label': 'Dubai (GST)'},
    {'value': 'Asia/Kolkata', 'label': 'India (IST)'},
    {'value': 'Asia/Bangkok', 'label': 'Bangkok (ICT)'},
    {'value': 'Asia/Singapore', 'label': 'Singapore (SGT)'},
    {'value': 'Asia/Hong_Kong', 'label': 'Hong Kong (HKT)'},
    {'value': 'Asia/Tokyo', 'label': 'Japan (JST)'},
    {'value': 'Australia/Sydney', 'label': 'Sydney (AEST)'},
    {'value': 'Australia/Perth', 'label': 'Perth (AWST)'},
    {'value': 'Pacific/Auckland', 'label': 'New Zealand (NZST)'},
  ];

  // Auto-detect the device's current timezone
  String? _detectDeviceTimezone() {
    try {
      // Initialize timezone data
      tz_data.initializeTimeZones();
      
      // Try to get the local timezone from the tz local (works on some platforms)
      final location = tz.local;
      final timezoneName = location.name;
      
      // If the local timezone name is valid (not empty), return it
      if (timezoneName.isNotEmpty) {
        return timezoneName;
      }
      
      // Fallback: Try to detect timezone from the device's current offset
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final offsetMinutes = offset.inMinutes;
      
      for (final tzItem in _commonTimezones) {
        final tzValue = tzItem['value'];
        if (tzValue != null) {
          try {
            final tzLocation = tz.getLocation(tzValue);
            final tzNow = tz.TZDateTime.now(tzLocation);
            final tzOffset = tzNow.timeZoneOffset;
            final tzTotalMinutes = tzOffset.inHours * 60 + tzOffset.inMinutes;
            if (tzTotalMinutes == offsetMinutes) {
              return tzValue;
            }
          } catch (_) {
            continue;
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Failed to detect timezone: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfile();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh profile data when app resumes
    if (state == AppLifecycleState.resumed && mounted) {
      _loadProfile();
    }
  }

  void _loadProfile() {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    if (widget.profileId == 'new') {
      final position = locationProvider.currentPosition;
      _profile = NotificationProfile(
        id: const Uuid().v4(),
        name: '',
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        radius: 0,
        minMagnitude: 4.5,
      );
    } else {
      _profile = settingsProvider.notificationProfiles
          .cast<NotificationProfile?>()
          .firstWhere(
            (p) => p?.id == widget.profileId,
            orElse: () => null,
          );
    }

    if (_profile == null) return;

    _nameController.text = _profile!.name;
    _latitudeController.text = _profile!.latitude.toString();
    _longitudeController.text = _profile!.longitude.toString();
    setState(() {});

    _minMagnitude = _profile!.minMagnitude.clamp(0, 9);
    _radius = _profile!.radius.clamp(0, 5000);
    _quietHoursEnabled = _profile!.quietHoursEnabled;
    _quietHoursStart = List.from(_profile!.quietHoursStart);
    _quietHoursEnd = List.from(_profile!.quietHoursEnd);
    _quietHoursDays = List.from(_profile!.quietHoursDays);
    _alwaysNotifyRadiusEnabled = _profile!.alwaysNotifyRadiusEnabled;
    _alwaysNotifyRadiusValue = _profile!.alwaysNotifyRadiusValue.clamp(0, 500);
    _emergencyMagnitudeThreshold = _profile!.emergencyMagnitudeThreshold.clamp(0, 9);
    _emergencyRadius = _profile!.emergencyRadius.clamp(0, 1000);
    _globalMinMagnitudeOverrideQuietHours = _profile!.globalMinMagnitudeOverrideQuietHours.clamp(0, 9);
    
    // Auto-detect timezone for new profiles, or use saved timezone
    if (_profile!.timezone == null || _profile!.timezone!.isEmpty) {
      _timezone = _detectDeviceTimezone();
    } else {
      _timezone = _profile!.timezone;
    }
  }

  void _saveProfile() async {
    if (_profile == null) return;
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);

      final updatedProfile = _profile!.copyWith(
        name: _nameController.text,
        minMagnitude: _minMagnitude,
        radius: _radius,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        quietHoursEnabled: _quietHoursEnabled,
        quietHoursStart: _quietHoursStart,
        quietHoursEnd: _quietHoursEnd,
        quietHoursDays: _quietHoursDays,
        alwaysNotifyRadiusEnabled: _alwaysNotifyRadiusEnabled,
        alwaysNotifyRadiusValue: _alwaysNotifyRadiusValue,
        emergencyMagnitudeThreshold: _emergencyMagnitudeThreshold,
        emergencyRadius: _emergencyRadius,
        globalMinMagnitudeOverrideQuietHours:
            _globalMinMagnitudeOverrideQuietHours,
        timezone: _timezone,
      );

      if (widget.profileId == 'new') {
        await settingsProvider.addProfile(updatedProfile);
      } else {
        await settingsProvider.updateProfile(updatedProfile);
      }
      if (mounted) GoRouter.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    if (!settingsProvider.isLoaded || _profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Profile...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile Not Found')),
        body: const Center(
            child: Text(
                'The requested notification profile could not be found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _nameController.text.isEmpty ? 'Profile Detail' : _nameController.text),
        actions: [
          IconButton(
            tooltip: 'Save Profile Settings',
            icon: const Icon(Icons.check),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Basic Info Section
            Text(
              'Filter Name',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g., Home, Family, My Region',
                border: OutlineInputBorder(),
              ),
              autofillHints: const [AutofillHints.name],
              validator: (value) =>
                  (value == null || value.isEmpty)
                      ? 'Please enter a name'
                      : null,
            ),
            const SizedBox(height: 24),

            // Alert Area Section
            Text(
              'Alert Area',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    validator: (v) =>
                        double.tryParse(v ?? '') == null
                            ? 'Invalid'
                            : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    validator: (v) =>
                        double.tryParse(v ?? '') == null
                            ? 'Invalid'
                            : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Use Current Location',
                  onPressed: () async {
                    final lp = Provider.of<LocationProvider>(context,
                        listen: false);
                    await lp.determinePosition();
                    if (!mounted) return;
                    if (lp.currentPosition != null) {
                      setState(() {
                        _latitudeController.text =
                            lp.currentPosition!.latitude.toString();
                        _longitudeController.text =
                            lp.currentPosition!.longitude.toString();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSlider(
              label:
                  'Radius: ${_radius == 0 ? 'Worldwide' : '${_radius.toInt()} km'}',
              value: _radius,
              min: 0,
              max: 5000,
              divisions: 50,
              onChanged: (v) => setState(() => _radius = v),
            ),
            const SizedBox(height: 24),

            // Magnitude Threshold
            Text(
              'Magnitude Threshold',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSlider(
              label: 'Min Magnitude: ${_minMagnitude.toStringAsFixed(1)}',
              value: _minMagnitude,
              min: 0,
              max: 9,
              divisions: 90,
              onChanged: (v) => setState(() => _minMagnitude = v),
            ),
            const SizedBox(height: 24),

            // Quiet Hours
            Text(
              'Quiet Hours',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Enable Quiet Hours'),
              subtitle: const Text('Silences non-emergency alerts'),
              contentPadding: EdgeInsets.zero,
              value: _quietHoursEnabled,
              onChanged: (v) =>
                  setState(() => _quietHoursEnabled = v),
            ),
            if (_quietHoursEnabled) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Active Period'),
                subtitle: Text(
                    '${_formatTime(_quietHoursStart)} to ${_formatTime(_quietHoursEnd)}'),
                onTap: _pickQuietHoursRange,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Active Days'),
                subtitle: Text(_formatDays(_quietHoursDays)),
                onTap: _pickQuietDays,
              ),
              const SizedBox(height: 16),
              Text(
                'Alert me even during quiet hours if:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              _buildSlider(
                label:
                    'Magnitude ≥ ${_emergencyMagnitudeThreshold.toStringAsFixed(1)}',
                value: _emergencyMagnitudeThreshold,
                min: 0,
                max: 9,
                divisions: 90,
                onChanged: (v) =>
                    setState(() => _emergencyMagnitudeThreshold = v),
              ),
              _buildSlider(
                label:
                    'Distance ≤ ${_emergencyRadius.toInt()} km',
                value: _emergencyRadius,
                min: 0,
                max: 1000,
                divisions: 50,
                onChanged: (v) =>
                    setState(() => _emergencyRadius = v),
              ),
            ],
            const SizedBox(height: 24),

            // Timezone Section
            Text(
              'Timezone',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your local timezone for accurate quiet hours',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _timezone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select timezone',
              ),
              items: [
                const DropdownMenuItem<String>(
                  child: Text('Use device default'),
                ),
                ..._commonTimezones.map((tz) => DropdownMenuItem<String>(
                      value: tz['value'],
                      child: Text(tz['label']!),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _timezone = value;
                });
              },
            ),

            // Advanced Overrides
            Text(
              'Advanced Overrides',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSlider(
              label:
                  'Global Override: ${_globalMinMagnitudeOverrideQuietHours == 0 ? 'Disabled' : '≥ ${_globalMinMagnitudeOverrideQuietHours.toStringAsFixed(1)}'}',
              value: _globalMinMagnitudeOverrideQuietHours,
              min: 0,
              max: 9,
              divisions: 90,
              onChanged: (v) => setState(
                  () => _globalMinMagnitudeOverrideQuietHours = v),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Proximity Override'),
              subtitle:
                  const Text('Always notify within a small radius'),
              value: _alwaysNotifyRadiusEnabled,
              onChanged: (v) =>
                  setState(() => _alwaysNotifyRadiusEnabled = v),
            ),
            if (_alwaysNotifyRadiusEnabled)
              _buildSlider(
                label:
                    'Override Radius: ${_alwaysNotifyRadiusValue.toInt()} km',
                value: _alwaysNotifyRadiusValue,
                min: 0,
                max: 500,
                divisions: 50,
                onChanged: (v) =>
                    setState(() => _alwaysNotifyRadiusValue = v),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    double safeValue = value;
    if (value.isNaN || value.isInfinite || value < min || value > max) {
      safeValue = min;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Slider(
          value: safeValue,
          min: min,
          max: max,
          divisions: divisions,
          label: safeValue.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _formatDays(List<int> days) {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (days.length == 7) return 'Every day';
    if (days.isEmpty) return 'None';
    final sortedDays = List<int>.from(days)..sort();
    return sortedDays.map((d) => dayNames[d]).join(', ');
  }

  Future<void> _pickQuietDays() async {
    final selectedDays = List<int>.from(_quietHoursDays);
    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) => _DayPickerDialog(initialSelectedDays: selectedDays),
    );
    if (result != null) {
      setState(() {
        _quietHoursDays = result;
      });
    }
  }

  String _formatTime(List<int> time) {
    if (time.length < 2) return '--:--';
    final hour = time[0].toString().padLeft(2, '0');
    final minute = time[1].toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickQuietHoursRange() async {
    final startHour = _quietHoursStart.isNotEmpty ? _quietHoursStart[0] : 22;
    final startMinute = _quietHoursStart.length > 1 ? _quietHoursStart[1] : 0;
    final endHour = _quietHoursEnd.isNotEmpty ? _quietHoursEnd[0] : 6;
    final endMinute = _quietHoursEnd.length > 1 ? _quietHoursEnd[1] : 0;

    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: startHour, minute: startMinute),
      helpText: 'QUIET HOURS START',
    );
    if (start == null) return;
    if (!mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: endHour, minute: endMinute),
      helpText: 'QUIET HOURS END',
    );
    if (end == null) return;

    setState(() {
      _quietHoursStart = [start.hour, start.minute];
      _quietHoursEnd = [end.hour, end.minute];
    });
  }
}

class _DayPickerDialog extends StatefulWidget {
  final List<int> initialSelectedDays;

  const _DayPickerDialog({required this.initialSelectedDays});

  @override
  State<_DayPickerDialog> createState() => _DayPickerDialogState();
}

class _DayPickerDialogState extends State<_DayPickerDialog> {
  late List<bool> _selectedDays;
  static const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    final days = widget.initialSelectedDays;
    _selectedDays = List.generate(7, (index) => days.contains(index));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Active Days'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose which days quiet hours should be active',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                return FilterChip(
                  label: Text(dayNames[index]),
                  selected: _selectedDays[index],
                  onSelected: (selected) {
                    setState(() {
                      _selectedDays[index] = selected;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDays = List.generate(7, (_) => false);
                    });
                  },
                  child: const Text('Clear All'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDays = List.generate(7, (_) => true);
                    });
                  },
                  child: const Text('Select All'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final selectedDays = <int>[];
            for (int i = 0; i < 7; i++) {
              if (_selectedDays[i]) selectedDays.add(i);
            }
            Navigator.of(context).pop(selectedDays);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}
