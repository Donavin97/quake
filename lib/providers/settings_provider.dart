import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/time_window.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  AuthService? _authService;

  TimeWindow _timeWindow = TimeWindow.day;
  double _minMagnitude = 0.0;
  bool _notificationsEnabled = true;
  double _radius = 0.0;
  String _earthquakeProvider = 'usgs'; // Add this line

  TimeWindow get timeWindow => _timeWindow;

  double get minMagnitude => _minMagnitude;

  bool get notificationsEnabled => _notificationsEnabled;

  double get radius => _radius;

  String get earthquakeProvider => _earthquakeProvider; // Add this line

  SettingsProvider() {
    _loadPreferences();
  }

  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _timeWindow = TimeWindow.values[_prefs.getInt('timeWindow') ?? 0];
    _minMagnitude = _prefs.getDouble('minMagnitude') ?? 0.0;
    _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    _radius = _prefs.getDouble('radius') ?? 0.0;
    _earthquakeProvider = _prefs.getString('earthquakeProvider') ?? 'usgs'; // Add this line
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

  Future<void> setRadius(double value) async {
    final user = _authService?.currentUser;
    _radius = value;
    await _prefs.setDouble('radius', value);

    if (user != null) {
      Position? position;
      if (value > 0) {
        try {
          position = await _locationService.getCurrentPosition();
        } catch (e) {
          // Handle location errors
        }
      }
      await _firestoreService.saveUserPreferences(
        user.uid,
        {'radius': value},
        position: position,
      );
    }

    notifyListeners();
  }

  Future<void> setEarthquakeProvider(String value) async { // Add this method
    _earthquakeProvider = value;
    await _prefs.setString('earthquakeProvider', value);
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
