import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dart_geohash/dart_geohash.dart';

import '../models/time_window.dart';
import '../services/background_service.dart';
import '../services/user_service.dart';
import 'location_provider.dart';

class SettingsProvider with ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _userService = UserService();
  final LocationProvider _locationProvider;

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

  SettingsProvider(this._locationProvider) {
    _loadPreferences();
    _auth.userChanges().listen((user) {
      if (user != null) {
        _loadPreferences();
      }
    });
    _locationProvider.locationStream.listen((_) {
      _updateSubscriptions();
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

    final newTopics = <String>{'global'};
    for (var i = _minMagnitude; i <= 8; i++) {
      newTopics.add('magnitude_$i');
    }

    final position = _locationProvider.currentPosition;
    if (position != null) {
      final geohash = GeoHasher().encode(position.longitude, position.latitude);
      for (int i = 4; i <= 6; i++) {
        newTopics.add('geohash_${geohash.substring(0, i)}');
      }
    }

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
