import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

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
    extends State<NotificationProfileDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  NotificationProfile? _profile;
  late TextEditingController _nameController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  bool _isInitialized = false;

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
  }

  void _initializeProfile(
      SettingsProvider settingsProvider, LocationProvider locationProvider) {
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

    _nameController.text = _profile?.name ?? '';
    _latitudeController.text = _profile?.latitude.toString() ?? '0.0';
    _longitudeController.text = _profile?.longitude.toString() ?? '0.0';

    _minMagnitude = _profile?.minMagnitude.clamp(0, 9) ?? 4.5;
    _radius = _profile?.radius.clamp(0, 5000) ?? 0.0;
    _quietHoursEnabled = _profile?.quietHoursEnabled ?? false;
    _quietHoursStart = List.from(_profile?.quietHoursStart ?? [22, 0]);
    _quietHoursEnd = List.from(_profile?.quietHoursEnd ?? [6, 0]);
    _quietHoursDays = List.from(_profile?.quietHoursDays ?? [0, 1, 2, 3, 4, 5, 6]);
    _alwaysNotifyRadiusEnabled = _profile?.alwaysNotifyRadiusEnabled ?? false;
    _alwaysNotifyRadiusValue =
        _profile?.alwaysNotifyRadiusValue.clamp(0, 500) ?? 0.0;
    _emergencyMagnitudeThreshold =
        _profile?.emergencyMagnitudeThreshold.clamp(0, 9) ?? 5.0;
    _emergencyRadius = _profile?.emergencyRadius.clamp(0, 1000) ?? 100.0;
    _globalMinMagnitudeOverrideQuietHours =
        _profile?.globalMinMagnitudeOverrideQuietHours.clamp(0, 9) ?? 0.0;

    _isInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
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
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);

    if (!settingsProvider.isLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Profile...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isInitialized) {
      _initializeProfile(settingsProvider, locationProvider);
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
          padding: const EdgeInsets.all(12.0),
          children: [
            _buildSectionHeader('Basic Info'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Filter Name',
                        hintText: 'e.g., Home, Family, My Region',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty)
                              ? 'Please enter a name'
                              : null,
                    ),
                  ],
                ),
              ),
            ),
            _buildSectionHeader('Alert Area'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            decoration:
                                const InputDecoration(labelText: 'Latitude'),
                            keyboardType: TextInputType.number,
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
                            decoration:
                                const InputDecoration(labelText: 'Longitude'),
                            keyboardType: TextInputType.number,
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
                    const SizedBox(height: 12),
                    _buildSlider(
                      label:
                          'Radius: ${_radius == 0 ? 'Worldwide' : '${_radius.toInt()} km'}',
                      value: _radius,
                      min: 0,
                      max: 5000,
                      divisions: 50,
                      onChanged: (v) => setState(() => _radius = v),
                    ),
                  ],
                ),
              ),
            ),
            _buildSectionHeader('Magnitude Threshold'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildSlider(
                  label: 'Min Magnitude: ${_minMagnitude.toStringAsFixed(1)}',
                  value: _minMagnitude,
                  min: 0,
                  max: 9,
                  divisions: 90,
                  onChanged: (v) => setState(() => _minMagnitude = v),
                ),
              ),
            ),
            _buildSectionHeader('Quiet Hours'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Quiet Hours'),
                    subtitle: const Text('Silences non-emergency alerts'),
                    value: _quietHoursEnabled,
                    onChanged: (v) =>
                        setState(() => _quietHoursEnabled = v),
                  ),
                  if (_quietHoursEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Active Period'),
                      subtitle: Text(
                          '${_formatTime(_quietHoursStart)} to ${_formatTime(_quietHoursEnd)}'),
                      onTap: _pickQuietHoursRange,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      child: Text('Active Days',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildDayPicker(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            _buildSectionHeader('Advanced Overrides'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildSlider(
                      label:
                          'Global Override: ${_globalMinMagnitudeOverrideQuietHours == 0 ? 'Disabled' : 'Always notify if ≥ ${_globalMinMagnitudeOverrideQuietHours.toStringAsFixed(1)}'}',
                      value: _globalMinMagnitudeOverrideQuietHours,
                      min: 0,
                      max: 9,
                      divisions: 90,
                      onChanged: (v) => setState(
                          () => _globalMinMagnitudeOverrideQuietHours = v),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Proximity Override'),
                      subtitle:
                          const Text('Always notify within a small radius'),
                      contentPadding: EdgeInsets.zero,
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
                  ],
                ),
              ),
            ),
            if (_quietHoursEnabled) ...[
              _buildSectionHeader('Emergency Thresholds'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Text(
                        'Alert me even during quiet hours if:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      _buildSlider(
                        label:
                            'Mag ≥ ${_emergencyMagnitudeThreshold.toStringAsFixed(1)}',
                        value: _emergencyMagnitudeThreshold,
                        min: 0,
                        max: 9,
                        divisions: 90,
                        onChanged: (v) =>
                            setState(() => _emergencyMagnitudeThreshold = v),
                      ),
                      _buildSlider(
                        label:
                            'And distance ≤ ${_emergencyRadius.toInt()} km',
                        value: _emergencyRadius,
                        min: 0,
                        max: 1000,
                        divisions: 50,
                        onChanged: (v) =>
                            setState(() => _emergencyRadius = v),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, top: 16.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
          letterSpacing: 1.1,
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
    final safeValue = value.clamp(min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
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

  Widget _buildDayPicker() {
    return Center(
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('S'), tooltip: 'Sunday'),
          ButtonSegment(value: 1, label: Text('M'), tooltip: 'Monday'),
          ButtonSegment(value: 2, label: Text('T'), tooltip: 'Tuesday'),
          ButtonSegment(value: 3, label: Text('W'), tooltip: 'Wednesday'),
          ButtonSegment(value: 4, label: Text('T'), tooltip: 'Thursday'),
          ButtonSegment(value: 5, label: Text('F'), tooltip: 'Friday'),
          ButtonSegment(value: 6, label: Text('S'), tooltip: 'Saturday'),
        ],
        selected: _quietHoursDays.toSet(),
        onSelectionChanged: (newSelection) {
          setState(() {
            _quietHoursDays = newSelection.toList()..sort();
          });
        },
        multiSelectionEnabled: true,
        emptySelectionAllowed: true,
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  String _formatTime(List<int> time) {
    final hour = time[0].toString().padLeft(2, '0');
    final minute = time[1].toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickQuietHoursRange() async {
    final start = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _quietHoursStart[0], minute: _quietHoursStart[1]),
      helpText: 'QUIET HOURS START',
    );
    if (start == null) return;

    if (!mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _quietHoursEnd[0], minute: _quietHoursEnd[1]),
      helpText: 'QUIET HOURS END',
    );
    if (end == null) return;

    setState(() {
      _quietHoursStart = [start.hour, start.minute];
      _quietHoursEnd = [end.hour, end.minute];
    });
  }
}
