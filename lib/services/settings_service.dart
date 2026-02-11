
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quaketrack/models/time_window.dart';

class SettingsService {
  static const _minMagnitudeKey = 'min_magnitude';
  static const _timeWindowKey = 'time_window';
  static const _radiusKey = 'radius';

  Future<double> getMinMagnitude() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_minMagnitudeKey) ?? 5.0;
  }

  Future<void> setMinMagnitude(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_minMagnitudeKey, value);
  }

  Future<TimeWindow> getTimeWindow() async {
    final prefs = await SharedPreferences.getInstance();
    final timeWindowIndex = prefs.getInt(_timeWindowKey) ?? 0;
    return TimeWindow.values[timeWindowIndex];
  }

  Future<void> setTimeWindow(TimeWindow value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timeWindowKey, value.index);
  }

  Future<double> getRadius() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_radiusKey) ?? 500.0;
  }

  Future<void> setRadius(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_radiusKey, value);
  }
}
