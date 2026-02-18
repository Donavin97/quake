import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:hive/hive.dart';

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

  // New quiet hours and emergency override fields
  var _quietHoursEnabled = false;
  var _quietHoursStart = const [22, 0];
  var _quietHoursEnd = const [6, 0];
  var _quietHoursDays = const [0, 1, 2, 3, 4, 5, 6];
  var _emergencyMagnitudeThreshold = 5.0;
  var _emergencyRadius = 100.0;
  // New override fields
  var _globalMinMagnitudeOverrideQuietHours = 0.0;
  var _alwaysNotifyRadiusEnabled = false;
  var _alwaysNotifyRadiusValue = 0.0;

  ThemeMode get themeMode => _themeMode;
  TimeWindow get timeWindow => _timeWindow;
  int get minMagnitude => _minMagnitude;
  bool get notificationsEnabled => _notificationsEnabled;
  double get radius => _radius;
  String get earthquakeProvider => _earthquakeProvider;

  // New getters
  bool get quietHoursEnabled => _quietHoursEnabled;
  List<int> get quietHoursStart => _quietHoursStart;
  List<int> get quietHoursEnd => _quietHoursEnd;
  List<int> get quietHoursDays => _quietHoursDays;
  double get emergencyMagnitudeThreshold => _emergencyMagnitudeThreshold;
  double get emergencyRadius => _emergencyRadius;
  // New getters for override fields
  double get globalMinMagnitudeOverrideQuietHours => _globalMinMagnitudeOverrideQuietHours;
  bool get alwaysNotifyRadiusEnabled => _alwaysNotifyRadiusEnabled;
  double get alwaysNotifyRadiusValue => _alwaysNotifyRadiusValue;

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
        _subscribedTopics = Set<String>.from(preferences['subscribedTopics'] ?? []);

        // Load new quiet hours preferences
        _quietHoursEnabled = preferences['quietHoursEnabled'] ?? false;
        _quietHoursStart = (preferences['quietHoursStart'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [22, 0];
        _quietHoursEnd = (preferences['quietHoursEnd'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [6, 0];
        _quietHoursDays = (preferences['quietHoursDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [0, 1, 2, 3, 4, 5, 6];
        _emergencyMagnitudeThreshold = (preferences['emergencyMagnitudeThreshold'] as num?)?.toDouble() ?? 5.0;
        _emergencyRadius = (preferences['emergencyRadius'] as num?)?.toDouble() ?? 100.0;
        // Load new override preferences
        _globalMinMagnitudeOverrideQuietHours = (preferences['globalMinMagnitudeOverrideQuietHours'] as num?)?.toDouble() ?? 0.0;
        _alwaysNotifyRadiusEnabled = preferences['alwaysNotifyRadiusEnabled'] as bool? ?? false;
        _alwaysNotifyRadiusValue = (preferences['alwaysNotifyRadiusValue'] as num?)?.toDouble() ?? 0.0;
      }
    }
    await _updateSubscriptions();
    await _saveToLocalCache();
    notifyListeners();
  }

  Future<void> _saveToLocalCache() async {
    final box = await Hive.openBox('app_settings');
    await box.putAll({
      'minMagnitude': _minMagnitude,
      'notificationsEnabled': _notificationsEnabled,
      'radius': _radius,
      'quietHoursEnabled': _quietHoursEnabled,
      'quietHoursStart': _quietHoursStart,
      'quietHoursEnd': _quietHoursEnd,
      'quietHoursDays': _quietHoursDays,
      'emergencyMagnitudeThreshold': _emergencyMagnitudeThreshold,
      'emergencyRadius': _emergencyRadius,
      'globalMinMagnitudeOverrideQuietHours': _globalMinMagnitudeOverrideQuietHours,
      'alwaysNotifyRadiusEnabled': _alwaysNotifyRadiusEnabled,
      'alwaysNotifyRadiusValue': _alwaysNotifyRadiusValue,
    });
  }

  Future<void> _savePreferences() async {
    final user = _auth.currentUser;
    if (user != null) {
      final fcmToken = await FirebaseMessaging.instance.getToken(); // Get FCM token
      final position = _locationProvider.currentPosition;
      final preferences = {
        'themeMode': _themeMode.index,
        'timeWindow': _timeWindow.index,
        'minMagnitude': _minMagnitude,
        'notificationsEnabled': _notificationsEnabled,
        'radius': _radius,
        'earthquakeProvider': _earthquakeProvider,
        'subscribedTopics': _subscribedTopics.toList(),
        // Save new quiet hours preferences
        'quietHoursEnabled': _quietHoursEnabled,
        'quietHoursStart': _quietHoursStart,
        'quietHoursEnd': _quietHoursEnd,
        'quietHoursDays': _quietHoursDays,
        'emergencyMagnitudeThreshold': _emergencyMagnitudeThreshold,
        'emergencyRadius': _emergencyRadius,
        // Save new override preferences
        'globalMinMagnitudeOverrideQuietHours': _globalMinMagnitudeOverrideQuietHours,
        'alwaysNotifyRadiusEnabled': _alwaysNotifyRadiusEnabled,
        'alwaysNotifyRadiusValue': _alwaysNotifyRadiusValue,
      };
      await _userService.saveUserPreferences(user.uid, preferences, fcmToken: fcmToken, position: position); // Pass FCM token and position
      await _saveToLocalCache();
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

  // New setters for quiet hours and emergency override
  Future<void> setQuietHoursEnabled(bool enabled) async {
    _quietHoursEnabled = enabled;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setQuietHoursStart(List<int> time) async {
    _quietHoursStart = time;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setQuietHoursEnd(List<int> time) async {
    _quietHoursEnd = time;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setQuietHoursDays(List<int> days) async {
    _quietHoursDays = days;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setEmergencyMagnitudeThreshold(double magnitude) async {
    _emergencyMagnitudeThreshold = magnitude;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setEmergencyRadius(double radius) async {
    _emergencyRadius = radius;
    await _savePreferences();
    notifyListeners();
  }

  // New setters for override fields
  Future<void> setGlobalMinMagnitudeOverrideQuietHours(double magnitude) async {
    _globalMinMagnitudeOverrideQuietHours = magnitude;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setAlwaysNotifyRadiusEnabled(bool enabled) async {
    _alwaysNotifyRadiusEnabled = enabled;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setAlwaysNotifyRadiusValue(double value) async {
    _alwaysNotifyRadiusValue = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> _updateSubscriptions() async {
    if (!_notificationsEnabled) return;

    final newTopics = <String>{'global'};
    
    // Subscribe to all magnitude levels from our minimum up to 9.
    // This ensures that if an earthquake of magnitude 7 occurs and the 
    // backend sends to 'minmag_7', a user with a threshold of 4 (subscribed to minmag_4..9) will receive it.
    for (int i = _minMagnitude; i <= 9; i++) {
      newTopics.add('minmag_$i');
    }

    final position = _locationProvider.currentPosition;
    if (position != null) {
      final geohash = GeoHasher().encode(position.longitude, position.latitude);
      // Use 1 and 2 character prefixes for broad and local geohash topics
      newTopics.add('geo_${geohash.substring(0, 1)}');
      newTopics.add('geo_${geohash.substring(0, 2)}');
    }

    final toAdd = newTopics.difference(_subscribedTopics);
    final toRemove = _subscribedTopics.difference(newTopics);

    for (final topic in toAdd) {
      try {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
        _subscribedTopics.add(topic);
      } catch (e) {
        debugPrint('Error subscribing to topic $topic: $e');
      }
    }

    for (final topic in toRemove) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        _subscribedTopics.remove(topic);
      } catch (e) {
        debugPrint('Error unsubscribing from topic $topic: $e');
      }
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
