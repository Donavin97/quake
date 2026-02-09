
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/models/time_window.dart';

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
    final timeWindowString = prefs.getString(_timeWindowKey) ?? 'day';
    return TimeWindow.values.firstWhere((e) => e.toString().split('.').last == timeWindowString);
  }

  Future<void> setTimeWindow(TimeWindow value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeWindowKey, value.toString().split('.').last);
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
