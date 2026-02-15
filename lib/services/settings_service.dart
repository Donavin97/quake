
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quaketrack/models/time_window.dart';

class SettingsService {
  static const _minMagnitudeKey = 'min_magnitude';
  static const _timeWindowKey = 'time_window';
  static const _radiusKey = 'radius';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<double> getMinMagnitude() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_minMagnitudeKey) ?? 5.0;
  }

  Future<void> setMinMagnitude(double value) async {
    final prefs = await SharedPreferences.getInstance();
    final oldMagnitude = await getMinMagnitude();
    await prefs.setDouble(_minMagnitudeKey, value);
    await _updateTopicSubscription(oldMagnitude, value);
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

  Future<void> _updateTopicSubscription(
      double oldMagnitude, double newMagnitude) async {
    await unsubscribeFromTopic(oldMagnitude);
    await subscribeToTopic(newMagnitude);
  }

  Future<void> subscribeToTopic(double magnitude) async {
    final topic = 'minmag_${magnitude.toInt()}';
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(double magnitude) async {
    final topic = 'minmag_${magnitude.toInt()}';
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
