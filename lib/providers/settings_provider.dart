import 'package:flutter/material.dart';
import 'package:myapp/services/settings_service.dart';

enum TimeWindow {
  day,
  week,
  month,
}

class SettingsProvider with ChangeNotifier {
  double _minMagnitude = 0.0;
  TimeWindow _timeWindow = TimeWindow.day;
  double _radius = 500.0;

  final SettingsService _settingsService = SettingsService();

  SettingsProvider() {
    _loadMinMagnitude();
    _loadTimeWindow();
    _loadRadius();
  }

  double get minMagnitude => _minMagnitude;
  TimeWindow get timeWindow => _timeWindow;
  double get radius => _radius;

  void _loadMinMagnitude() async {
    _minMagnitude = await _settingsService.getMinMagnitude();
    notifyListeners();
  }

  void _loadTimeWindow() async {
    _timeWindow = await _settingsService.getTimeWindow();
    notifyListeners();
  }

  void _loadRadius() async {
    _radius = await _settingsService.getRadius();
    notifyListeners();
  }

  void setMinMagnitude(double value) {
    _minMagnitude = value;
    _settingsService.setMinMagnitude(value);
    notifyListeners();
  }

  void setTimeWindow(TimeWindow value) {
    _timeWindow = value;
    _settingsService.setTimeWindow(value);
    notifyListeners();
  }

  void setRadius(double value) {
    _radius = value;
    _settingsService.setRadius(value);
    notifyListeners();
  }

  int get timeWindowDays {
    switch (_timeWindow) {
      case TimeWindow.day:
        return 1;
      case TimeWindow.week:
        return 7;
      case TimeWindow.month:
        return 30;
    }
  }
}
