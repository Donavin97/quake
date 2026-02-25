import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/notification_profile.dart';
import '../providers/settings_provider.dart';
import '../providers/location_provider.dart'; // Import LocationProvider

class NotificationProfileDetailScreen extends StatefulWidget {
  final String profileId;

  const NotificationProfileDetailScreen({super.key, required this.profileId});

  @override
  State<NotificationProfileDetailScreen> createState() => _NotificationProfileDetailScreenState();
}

class _NotificationProfileDetailScreenState extends State<NotificationProfileDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late NotificationProfile _profile;
  late TextEditingController _nameController;
  late TextEditingController _minMagnitudeController;
  late TextEditingController _radiusController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  bool _quietHoursEnabled = false;
  List<int> _quietHoursStart = [];
  List<int> _quietHoursEnd = [];
  List<int> _quietHoursDays = [];
  bool _alwaysNotifyRadiusEnabled = false;
  late TextEditingController _alwaysNotifyRadiusValueController;
  late TextEditingController _emergencyMagnitudeThresholdController;
  late TextEditingController _emergencyRadiusController;


  @override
  void initState() {
    super.initState();
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _profile = settingsProvider.notificationProfiles.firstWhere((p) => p.id == widget.profileId);

    _nameController = TextEditingController(text: _profile.name);
    _minMagnitudeController = TextEditingController(text: _profile.minMagnitude.toStringAsFixed(1));
    _radiusController = TextEditingController(text: _profile.radius.toStringAsFixed(0));
    _latitudeController = TextEditingController(text: _profile.latitude.toString());
    _longitudeController = TextEditingController(text: _profile.longitude.toString());
    _quietHoursEnabled = _profile.quietHoursEnabled;
    _quietHoursStart = List.from(_profile.quietHoursStart);
    _quietHoursEnd = List.from(_profile.quietHoursEnd);
    _quietHoursDays = List.from(_profile.quietHoursDays);
    _alwaysNotifyRadiusEnabled = _profile.alwaysNotifyRadiusEnabled;
    _alwaysNotifyRadiusValueController = TextEditingController(text: _profile.alwaysNotifyRadiusValue.toStringAsFixed(0));
    _emergencyMagnitudeThresholdController = TextEditingController(text: _profile.emergencyMagnitudeThreshold.toStringAsFixed(1));
    _emergencyRadiusController = TextEditingController(text: _profile.emergencyRadius.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minMagnitudeController.dispose();
    _radiusController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _alwaysNotifyRadiusValueController.dispose();
    _emergencyMagnitudeThresholdController.dispose();
    _emergencyRadiusController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

      final updatedProfile = _profile.copyWith(
        name: _nameController.text,
        minMagnitude: double.parse(_minMagnitudeController.text),
        radius: double.parse(_radiusController.text),
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        quietHoursEnabled: _quietHoursEnabled,
        quietHoursStart: _quietHoursStart,
        quietHoursEnd: _quietHoursEnd,
        quietHoursDays: _quietHoursDays,
        alwaysNotifyRadiusEnabled: _alwaysNotifyRadiusEnabled,
        alwaysNotifyRadiusValue: double.parse(_alwaysNotifyRadiusValueController.text),
        emergencyMagnitudeThreshold: double.parse(_emergencyMagnitudeThresholdController.text),
        emergencyRadius: double.parse(_emergencyRadiusController.text),
      );

      await settingsProvider.updateProfile(updatedProfile);
      GoRouter.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile.name),
        actions: [
          IconButton(
            tooltip: 'Save Profile Settings', // Add this line
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Profile Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a profile name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _minMagnitudeController,
                decoration: const InputDecoration(labelText: 'Minimum Magnitude'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _radiusController,
                decoration: const InputDecoration(labelText: 'Radius (km, 0 for Worldwide)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              // Latitude and Longitude fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty || double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Use Current Location',
                    onPressed: () async {
                      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                      await locationProvider.determinePosition();
                      final position = locationProvider.currentPosition;
                      if (position != null) {
                        setState(() {
                          _latitudeController.text = position.latitude.toString();
                          _longitudeController.text = position.longitude.toString();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Updated to current location')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not determine location')),
                        );
                      }
                    },
                  ),
                ],
              ),
              // Quiet Hours Enabled
              SwitchListTile(
                title: const Text('Quiet Hours Enabled'),
                value: _quietHoursEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _quietHoursEnabled = value;
                  });
                },
              ),
              // Quiet Hours Start
              ListTile(
                title: Text('Quiet Hours Start: ${_quietHoursStart[0].toString().padLeft(2, '0')}:${_quietHoursStart[1].toString().padLeft(2, '0')}'),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: _quietHoursStart[0], minute: _quietHoursStart[1]),
                  );
                  if (picked != null) {
                    setState(() {
                      _quietHoursStart = [picked.hour, picked.minute];
                    });
                  }
                },
              ),
              // Quiet Hours End
              ListTile(
                title: Text('Quiet Hours End: ${_quietHoursEnd[0].toString().padLeft(2, '0')}:${_quietHoursEnd[1].toString().padLeft(2, '0')}'),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: _quietHoursEnd[0], minute: _quietHoursEnd[1]),
                  );
                  if (picked != null) {
                    setState(() {
                      _quietHoursEnd = [picked.hour, picked.minute];
                    });
                  }
                },
              ),
              // Quiet Hours Days
              ListTile(
                title: const Text('Quiet Hours Days'),
                subtitle: Text(_quietHoursDays.map((day) => _getDayName(day)).join(', ')),
                onTap: () async {
                  // This would ideally open a multi-select dialog for days
                  // For simplicity, we'll just toggle a few for now
                  // A full implementation would involve a custom dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Days selection not yet implemented.')),
                  );
                },
              ),

              const Divider(),

              // Always Notify Radius Enabled
              SwitchListTile(
                title: const Text('Always Notify Radius Enabled'),
                value: _alwaysNotifyRadiusEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _alwaysNotifyRadiusEnabled = value;
                  });
                },
              ),
              // Always Notify Radius Value
              TextFormField(
                controller: _alwaysNotifyRadiusValueController,
                decoration: const InputDecoration(labelText: 'Always Notify Radius Value (km)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_alwaysNotifyRadiusEnabled && (value == null || value.isEmpty || double.tryParse(value) == null)) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                enabled: _alwaysNotifyRadiusEnabled,
              ),

              const Divider(),

              // Emergency Magnitude Threshold
              TextFormField(
                controller: _emergencyMagnitudeThresholdController,
                decoration: const InputDecoration(labelText: 'Emergency Magnitude Threshold'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              // Emergency Radius
              TextFormField(
                controller: _emergencyRadiusController,
                decoration: const InputDecoration(labelText: 'Emergency Radius (km)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayName(int dayIndex) {
    switch (dayIndex) {
      case 0: return 'Sunday';
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      default: return '';
    }
  }
}
