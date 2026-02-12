import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/time_window.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  TimeWindow _timeWindow = TimeWindow.day;
  double _minMagnitude = 0.0;
  bool _notificationsEnabled = true;

  TimeWindow get timeWindow => _timeWindow;

  double get minMagnitude => _minMagnitude;

  bool get notificationsEnabled => _notificationsEnabled;

  SettingsProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _timeWindow = TimeWindow.values[_prefs.getInt('timeWindow') ?? 0];
    _minMagnitude = _prefs.getDouble('minMagnitude') ?? 0.0;
    _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> setTimeWindow(TimeWindow value) async {
    _timeWindow = value;
    await _prefs.setInt('timeWindow', value.index);
    notifyListeners();
  }

  Future<void> setMinMagnitude(double value) async {
    final oldMagnitude = _minMagnitude.floor();
    final newMagnitude = value.floor();

    if (oldMagnitude != newMagnitude) {
      if (_notificationsEnabled) {
        await _firebaseMessaging
            .unsubscribeFromTopic('magnitude_$oldMagnitude');
        await _firebaseMessaging.subscribeToTopic('magnitude_$newMagnitude');
      }
    }

    _minMagnitude = value;
    await _prefs.setDouble('minMagnitude', value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool('notificationsEnabled', value);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> _updateTopicSubscriptions() async {
    if (_notificationsEnabled) {
      await _firebaseMessaging
          .subscribeToTopic('magnitude_${_minMagnitude.floor()}');
    } else {
      await _firebaseMessaging
          .unsubscribeFromTopic('magnitude_${_minMagnitude.floor()}');
    }
  }
}
