import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/time_window.dart';
import '../services/location_service.dart';
import '../services/user_service.dart';

class SettingsProvider with ChangeNotifier {
  final UserService _userService = UserService();
  final LocationService _locationService = LocationService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ThemeMode _themeMode = ThemeMode.system;
  TimeWindow _timeWindow = TimeWindow.day;
  double _minMagnitude = 0.0;
  bool _notificationsEnabled = true;
  double _radius = 0.0;
  String _earthquakeProvider = 'usgs';

  ThemeMode get themeMode => _themeMode;
  TimeWindow get timeWindow => _timeWindow;
  double get minMagnitude => _minMagnitude;
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
        _minMagnitude = preferences['minMagnitude'] ?? 0.0;
        _notificationsEnabled = preferences['notificationsEnabled'] ?? true;
        _radius = preferences['radius'] ?? 0.0;
        _earthquakeProvider = preferences['earthquakeProvider'] ?? 'usgs';
      }
    }
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final user = _auth.currentUser;
    if (user != null) {
      final preferences = {
        'themeMode': _themeMode.index,
        'timeWindow': _timeWindow.index,
        'minMagnitude': _minMagnitude,
        'notificationsEnabled': _notificationsEnabled,
        'radius': _radius,
        'earthquakeProvider': _earthquakeProvider,
      };
      Position? position;
      if (_radius > 0) {
        try {
          position = await _locationService.getCurrentPosition();
        } catch (e) {
          // Handle location errors
        }
      }
      await _userService.saveUserPreferences(user.uid, preferences, position: position);
    }
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setTimeWindow(TimeWindow value) async {
    _timeWindow = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setMinMagnitude(double value) async {
    final oldMagnitude = _minMagnitude.floor();
    final newMagnitude = value.floor();

    if (oldMagnitude != newMagnitude) {
      if (_notificationsEnabled) {
        await _firebaseMessaging.unsubscribeFromTopic('magnitude_$oldMagnitude');
        await _firebaseMessaging.subscribeToTopic('magnitude_$newMagnitude');
      }
    }

    _minMagnitude = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _savePreferences();
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> setRadius(double value) async {
    _radius = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setEarthquakeProvider(String value) async {
    _earthquakeProvider = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> _updateTopicSubscriptions() async {
    if (_notificationsEnabled) {
      await _firebaseMessaging.subscribeToTopic('magnitude_${_minMagnitude.floor()}');
    } else {
      await _firebaseMessaging.unsubscribeFromTopic('magnitude_${_minMagnitude.floor()}');
    }
  }
}
