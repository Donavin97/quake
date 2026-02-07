
import 'package:flutter/material.dart';

enum TimeWindow {
  day,
  week,
  month,
}

class SettingsProvider with ChangeNotifier {
  double _minMagnitude = 0.0;
  TimeWindow _timeWindow = TimeWindow.day;

  double get minMagnitude => _minMagnitude;
  TimeWindow get timeWindow => _timeWindow;

  void setMinMagnitude(double value) {
    _minMagnitude = value;
    notifyListeners();
  }

  void setTimeWindow(TimeWindow value) {
    _timeWindow = value;
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
