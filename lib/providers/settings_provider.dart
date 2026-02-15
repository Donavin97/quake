import 'package:dart_geohash/dart_geohash.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  ThemeMode _themeMode = ThemeMode.system;
  TimeWindow _timeWindow = TimeWindow.day;
  int _minMagnitude = 0;
  bool _notificationsEnabled = true;
  double _radius = 0.0;
  String _earthquakeProvider = 'usgs';
  Set<String> _subscribedTopics = {};

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
      final preferences = {
        'themeMode': _themeMode.index,
        'timeWindow': _timeWindow.index,
        'minMagnitude': _minMagnitude,
        'notificationsEnabled': _notificationsEnabled,
        'radius': _radius,
        'earthquakeProvider': _earthquakeProvider,
        'subscribedTopics': _subscribedTopics.toList(),
      };
      Position? position;
      if (_radius > 0) {
        try {
          position = await _locationService.getCurrentPosition();
        } catch (e) {
          // Handle location errors
        }
      }
      await _userService.saveUserPreferences(user.uid, preferences,
          position: position);
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

  Future<void> setMinMagnitude(int value) async {
    _minMagnitude = value;
    await _savePreferences();
    await _updateSubscriptions();
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _savePreferences();
    await _updateSubscriptions();
    notifyListeners();
  }

  Future<void> setRadius(double value) async {
    _radius = value;
    await _savePreferences();
    await _updateSubscriptions();
    notifyListeners();
  }

  Future<void> setEarthquakeProvider(String value) async {
    _earthquakeProvider = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> _updateSubscriptions() async {
    // Unsubscribe from old topics
    for (final topic in _subscribedTopics) {
      await _messaging.unsubscribeFromTopic(topic);
    }
    _subscribedTopics.clear();

    if (!_notificationsEnabled) {
      await _savePreferences();
      return;
    }

    if (_radius == 0) {
      // Subscribe to global magnitude topics
      for (int mag = _minMagnitude; mag <= 10; mag++) {
        final topic = 'magnitude_$mag';
        await _messaging.subscribeToTopic(topic);
        _subscribedTopics.add(topic);
      }
    } else {
      // Subscribe to location-based topics
      Position? position;
      try {
        position = await _locationService.getCurrentPosition();
      } catch (e) {
        // Handle location errors
        return;
      }

      final geohasher = GeoHasher();
      final precision = _getGeohashPrecision(_radius);
      final centerGeohash =
          geohasher.encode(position.longitude, position.latitude, precision: precision);
      final neighbors = geohasher.neighbors(centerGeohash);

      final geohashes = [centerGeohash, ...neighbors.values];

      for (int mag = _minMagnitude; mag <= 10; mag++) {
        for (final geohash in geohashes) {
            final topic = 'magnitude_${mag}_geohash_$geohash';
            await _messaging.subscribeToTopic(topic);
            _subscribedTopics.add(topic);
        }
      }
    }
    await _savePreferences();
  }


  int _getGeohashPrecision(double radius) {
    if (radius <= 1) return 6;
    if (radius <= 5) return 5;
    if (radius <= 40) return 4;
    if (radius <= 150) return 3;
    if (radius <= 1250) return 2;
    return 1;
  }
}
