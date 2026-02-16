import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _minMagnitudeKey = 'minMagnitude';

  Future<int> getMinMagnitude() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_minMagnitudeKey) ?? 0;
  }

  Future<void> setMinMagnitude(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_minMagnitudeKey, value);
  }

  Future<void> subscribeToTopic(int minMagnitude) async {
    final topics = List.generate(9, (i) => 'magnitude_$i');
    final currentTopic = 'magnitude_${minMagnitude.floor()}';

    for (final topic in topics) {
      if (topic == currentTopic) {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      }
    }
  }
}
