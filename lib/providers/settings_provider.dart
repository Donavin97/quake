import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/time_window.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;

  TimeWindow _timeWindow = TimeWindow.day;
  double _minMagnitude = 0.0;
  double _radius = 1000.0;

  TimeWindow get timeWindow => _timeWindow;
  double get minMagnitude => _minMagnitude;
  double get radius => _radius;

  SettingsProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _timeWindow = TimeWindow.values[_prefs.getInt('timeWindow') ?? 0];
    _minMagnitude = _prefs.getDouble('minMagnitude') ?? 0.0;
    _radius = _prefs.getDouble('radius') ?? 1000.0;
    notifyListeners();
  }

  Future<void> setTimeWindow(TimeWindow value) async {
    _timeWindow = value;
    await _prefs.setInt('timeWindow', value.index);
    notifyListeners();
  }

  Future<void> setMinMagnitude(double value) async {
    _minMagnitude = value;
    await _prefs.setDouble('minMagnitude', value);
    notifyListeners();
  }

  Future<void> setRadius(double value) async {
    _radius = value;
    await _prefs.setDouble('radius', value);
    notifyListeners();
  }
}
