import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_window.dart';

class SettingsProvider with ChangeNotifier {
  static const String _minMagnitudeKey = 'minMagnitude';
  static const String _timeWindowKey = 'timeWindow';
  static const String _radiusKey = 'radius';

  double _minMagnitude = 0.0;
  TimeWindow _timeWindow = TimeWindow.day;
  double _radius = 1000.0;

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double get minMagnitude => _minMagnitude;
  TimeWindow get timeWindow => _timeWindow;
  double get radius => _radius;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _minMagnitude = prefs.getDouble(_minMagnitudeKey) ?? 0.0;
    final timeWindowIndex = prefs.getInt(_timeWindowKey) ?? 0;
    _timeWindow = TimeWindow.values[timeWindowIndex];
    _radius = prefs.getDouble(_radiusKey) ?? 1000.0;
    notifyListeners();
  }

  Future<void> updateSettings({
    double? minMagnitude,
    TimeWindow? timeWindow,
    double? radius,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (e) {
      // Could not get position
    }
    if (minMagnitude != null) {
      _minMagnitude = minMagnitude;
      await prefs.setDouble(_minMagnitudeKey, minMagnitude);
    }
    if (timeWindow != null) {
      _timeWindow = timeWindow;
      await prefs.setInt(_timeWindowKey, timeWindow.index);
    }
    if (radius != null) {
      _radius = radius;
      await prefs.setDouble(_radiusKey, radius);
    }
    notifyListeners();
    final user = _auth.currentUser;
    if (user != null) {
      await _firestoreService.saveUserPreferences(
        user.uid,
        {
          'minMagnitude': _minMagnitude,
          'timeWindow': _timeWindow.index,
          'radius': _radius,
        },
        position: position,
      );
    }
  }

  Future<void> loadSettingsFromFirestore() async {
    final user = _auth.currentUser;
    if (user != null) {
      final prefs = await _firestoreService.getUserPreferences(user.uid);
      if (prefs != null) {
        _minMagnitude = prefs['minMagnitude'] ?? 0.0;
        _timeWindow = TimeWindow.values[prefs['timeWindow'] ?? 0];
        _radius = prefs['radius'] ?? 1000.0;
        notifyListeners();
      }
    }
  }

  Future<void> setMinMagnitude(double value) async {
    await updateSettings(minMagnitude: value);
  }
}
