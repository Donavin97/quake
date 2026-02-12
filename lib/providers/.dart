import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geohash_plus/geohash_plus.dart' hide LatLng;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/time_window.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  TimeWindow _timeWindow = TimeWindow.day;
  double _minMagnitude = 0.0;
  bool _notificationsEnabled = true;
  LatLng? _notificationLocation;
  double _notificationRadius = 100.0;
  Set<String> _currentGeohashes = {};

  TimeWindow get timeWindow => _timeWindow;

  double get minMagnitude => _minMagnitude;

  bool get notificationsEnabled => _notificationsEnabled;

  LatLng? get notificationLocation => _notificationLocation;

  double get notificationRadius => _notificationRadius;

  double get radius => _notificationRadius;

  SettingsProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _timeWindow = TimeWindow.values[_prefs.getInt('timeWindow') ?? 0];
    _minMagnitude = _prefs.getDouble('minMagnitude') ?? 0.0;
    _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    final lat = _prefs.getDouble('notificationLat');
    final lng = _prefs.getDouble('notificationLng');
    if (lat != null && lng != null) {
      _notificationLocation = LatLng(lat, lng);
    }
    _notificationRadius = _prefs.getDouble('notificationRadius') ?? 100.0;
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
        await _firebaseMessaging.unsubscribeFromTopic('magnitude_$oldMagnitude');
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

  Future<void> setNotificationLocation(LatLng location) async {
    _notificationLocation = location;
    await _prefs.setDouble('notificationLat', location.latitude);
    await _prefs.setDouble('notificationLng', location.longitude);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> setNotificationRadius(double radius) async {
    _notificationRadius = radius;
    await _prefs.setDouble('notificationRadius', radius);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> setRadius(double radius) async {
    await setNotificationRadius(radius);
  }

  Future<void> _updateTopicSubscriptions() async {
    if (_notificationsEnabled) {
      await _firebaseMessaging.subscribeToTopic('magnitude_${_minMagnitude.floor()}');
      if (_notificationLocation != null) {
        final newGeohashes = _calculateGeohashes(
            _notificationLocation!, _notificationRadius);
        await _updateGeohashSubscriptions(newGeohashes);
      }
    } else {
      await _firebaseMessaging.unsubscribeFromTopic('magnitude_${_minMagnitude.floor()}');
      await _updateGeohashSubscriptions({});
    }
  }

  Future<void> _updateGeohashSubscriptions(Set<String> newGeohashes) async {
    final oldGeohashes = _currentGeohashes;
    final toSubscribe = newGeohashes.difference(oldGeohashes);
    final toUnsubscribe = oldGeohashes.difference(newGeohashes);

    for (final geohash in toUnsubscribe) {
      await _firebaseMessaging.unsubscribeFromTopic(geohash);
    }
    for (final geohash in toSubscribe) {
      await _firebaseMessaging.subscribeToTopic(geohash);
    }

    _currentGeohashes = newGeohashes;
  }

  Set<String> _calculateGeohashes(LatLng center, double radius) {
    final Set<String> geohashes = {};
    final centerGeohash =
        encode(center.latitude, center.longitude, precision: 5);
    geohashes.add(centerGeohash);

    final neighborsResult = neighbors(centerGeohash);
    geohashes.addAll(neighborsResult.values);

    return geohashes;
  }
}
