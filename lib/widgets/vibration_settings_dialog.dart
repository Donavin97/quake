import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../models/user_preferences.dart';

class VibrationSettingsDialog extends ConsumerStatefulWidget {
  const VibrationSettingsDialog({super.key});

  @override
  ConsumerState<VibrationSettingsDialog> createState() => _VibrationSettingsDialogState();
}

class _VibrationSettingsDialogState extends ConsumerState<VibrationSettingsDialog> {
  late int _successDuration;
  late int _successPattern;
  late int _errorDuration;
  late int _errorPattern;
  bool _initialized = false;

  void _initialize(SettingsState settings) {
    _successDuration = settings.userPreferences.successVibration.duration;
    _successPattern = settings.userPreferences.successVibration.pattern;
    _errorDuration = settings.userPreferences.errorVibration.duration;
    _errorPattern = settings.userPreferences.errorVibration.pattern;
    _initialized = true;
  }

  void _saveSettings() {
    final notifier = ref.read(settingsProvider.notifier);
    notifier.setSuccessVibration(VibrationSettings(
      duration: _successDuration,
      pattern: _successPattern,
    ));
    notifier.setErrorVibration(VibrationSettings(
      duration: _errorDuration,
      pattern: _errorPattern,
    ));
    Navigator.of(context).pop();
  }

  void _testSuccessVibration() {
    final notifier = ref.read(settingsProvider.notifier);
    notifier.testSuccessVibration(VibrationSettings(
      duration: _successDuration,
      pattern: _successPattern,
    ));
  }

  void _testErrorVibration() {
    final notifier = ref.read(settingsProvider.notifier);
    notifier.testErrorVibration(VibrationSettings(
      duration: _errorDuration,
      pattern: _errorPattern,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    if (!_initialized) {
      _initialize(settings);
    }

    return AlertDialog(
      title: const Text('Vibration Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Success Vibration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSlider(
              label: 'Duration: $_successDuration ms',
              value: _successDuration.toDouble(),
              min: 10,
              max: 200,
              divisions: 19,
              onChanged: (value) {
                setState(() {
                  _successDuration = value.toInt();
                });
              },
            ),
            _buildSlider(
              label: 'Pulses: $_successPattern',
              value: _successPattern.toDouble(),
              min: 1,
              max: 3,
              divisions: 2,
              onChanged: (value) {
                setState(() {
                  _successPattern = value.round();
                });
              },
            ),
            Center(
              child: TextButton.icon(
                onPressed: _testSuccessVibration,
                icon: const Icon(Icons.vibration),
                label: const Text('Test Success'),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Error Vibration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSlider(
              label: 'Duration: $_errorDuration ms',
              value: _errorDuration.toDouble(),
              min: 50,
              max: 300,
              divisions: 25,
              onChanged: (value) {
                setState(() {
                  _errorDuration = value.toInt();
                });
              },
            ),
            _buildSlider(
              label: 'Pulses: $_errorPattern',
              value: _errorPattern.toDouble(),
              min: 1,
              max: 3,
              divisions: 2,
              onChanged: (value) {
                setState(() {
                  _errorPattern = value.round();
                });
              },
            ),
            Center(
              child: TextButton.icon(
                onPressed: _testErrorVibration,
                icon: const Icon(Icons.vibration),
                label: const Text('Test Error'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: const Text('Save'),
        ),
      ],
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
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Slider(
          value: safeValue,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
