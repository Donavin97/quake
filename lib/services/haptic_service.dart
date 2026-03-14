import 'package:vibration/vibration.dart';
import '../models/earthquake.dart';

class HapticService {
  /// Triggers a vibration pattern scaled to the magnitude of the earthquake.
  static Future<void> vibrateForEarthquake(Earthquake earthquake) async {
    final bool hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    final double magnitude = earthquake.magnitude;

    if (magnitude < 3.0) {
      // Light: Single short pulse
      await Vibration.vibrate(duration: 50);
    } else if (magnitude < 5.0) {
      // Medium: Longer single pulse
      await Vibration.vibrate(duration: 150);
    } else if (magnitude < 7.0) {
      // Strong: Two intense pulses
      await Vibration.vibrate(
        pattern: [0, 200, 100, 200],
        intensities: [0, 128, 0, 255],
      );
    } else {
      // Major: Long rumble pattern
      await Vibration.vibrate(
        pattern: [0, 500, 100, 500, 100, 500],
        intensities: [0, 255, 0, 255, 0, 255],
      );
    }
  }

  /// Triggers a simple success vibration.
  static Future<void> vibrateSuccess() async {
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate(duration: 100);
    }
  }

  /// Triggers a simple error vibration.
  static Future<void> vibrateError() async {
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
    }
  }
}
