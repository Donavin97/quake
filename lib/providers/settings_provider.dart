import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/time_window.dart';
import '../services/background_service.dart';
import '../services/user_service.dart';

class SettingsProvider with ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _userService = UserService();

  var _themeMode = ThemeMode.system;
  var _timeWindow = TimeWindow.day;
  var _minMagnitude = 0;
  var _notificationsEnabled = true;
  var _radius = 2000.0;
  var _earthquakeProvider = 'usgs';
  var _subscribedTopics = <String>{};

  ThemeMode get themeMode => _themeMode;
  TimeWindow get timeWindow => _timeWindow;
  int get minMagnitude => _minMagnitude;
  bool get notificationsEnabled => _notificationsEnabled;
  double get radius => _radius;
  String get earthquakeProvider => _earthquakeProvider;

  SettingsProvider() {
    _loadPreferences();
    _auth.userChanges().listen((user) {
      if (user != null) {
        _loadPreferences();
      }
    });
  }

  Future<void> _loadPreferences() async {
    final user = _auth.currentUser;
    if (user != null) {
      final preferences = await _userService.getUserPreferences(user.uid);
      if (preferences != null) {
        _themeMode = ThemeMode.values[preferences['themeMode'] ?? 0];
        _timeWindow = TimeWindow.values[preferences['timeWindow'] ?? 0];
        _minMagnitude = (preferences['minMagnitude'] as num? ?? 0).toInt();
        _notificationsEnabled = preferences['notificationsEnabled'] ?? true;
        _radius = (preferences['radius'] as num? ?? 0).toDouble();
        _earthquakeProvider = preferences['earthquakeProvider'] ?? 'usgs';
        _subscribedTopics =
            Set<String>.from(preferences['subscribedTopics'] ?? []);
      }
    }
    await _updateSubscriptions();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _userService.saveUserPreferences(user.uid, {
        'themeMode': _themeMode.index,
        'timeWindow': _timeWindow.index,
        'minMagnitude': _minMagnitude,
        'notificationsEnabled': _notificationsEnabled,
        'radius': _radius,
        'earthquakeProvider': _earthquakeProvider,
        'subscribedTopics': _subscribedTopics.toList(),
      });
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setTimeWindow(TimeWindow window) async {
    _timeWindow = window;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setMinMagnitude(int magnitude) async {
    _minMagnitude = magnitude;
    await _savePreferences();
    await _updateSubscriptions();
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _savePreferences();
    if (enabled) {
      await BackgroundService.requestPermission();
      await _updateSubscriptions();
    } else {
      await _unsubscribeFromAllTopics();
    }
    notifyListeners();
  }

  Future<void> setRadius(double radius) async {
    _radius = radius;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setEarthquakeProvider(String provider) async {
    _earthquakeProvider = provider;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> _updateSubscriptions() async {
    if (!_notificationsEnabled) return;

    final newTopics = {
      if (_minMagnitude >= 0) 'magnitude_0',
      if (_minMagnitude >= 1) 'magnitude_1',
      if (_minMagnitude >= 2) 'magnitude_2',
      if (_minMagnitude >= 3) 'magnitude_3',
      if (_minMagnitude >= 4) 'magnitude_4',
      if (_minMagnitude >= 5) 'magnitude_5',
      if (_minMagnitude >= 6) 'magnitude_6',
      if (_minMagnitude >= 7) 'magnitude_7',
      if (_minMagnitude >= 8) 'magnitude_8',
    };

    final toAdd = newTopics.difference(_subscribedTopics);
    final toRemove = _subscribedTopics.difference(newTopics);

    for (final topic in toAdd) {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      _subscribedTopics.add(topic);
    }

    for (final topic in toRemove) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      _subscribedTopics.remove(topic);
    }

    await _savePreferences();
  }

  Future<void> _unsubscribeFromAllTopics() async {
    for (final topic in _subscribedTopics) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    }
    _subscribedTopics.clear();
    await _savePreferences();
  }
}
