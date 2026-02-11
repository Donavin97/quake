import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/earthquake.dart';
import '../models/sort_criterion.dart';
import '../models/time_window.dart';
import '../services/usgs_service.dart';

class EarthquakeProvider with ChangeNotifier {
  final UsgsService _usgsService = UsgsService();

  List<Earthquake> _earthquakes = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;
  SortCriterion _sortCriterion = SortCriterion.date;

  List<Earthquake> get earthquakes => _earthquakes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  SortCriterion get sortCriterion => _sortCriterion;

  EarthquakeProvider();

  Future<void> fetchEarthquakes({Position? position}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final timeWindowIndex = prefs.getInt('timeWindow') ?? 0;
      final timeWindow = TimeWindow.values[timeWindowIndex];
      final minMagnitude = prefs.getDouble('minMagnitude') ?? 0.0;
      final radius = prefs.getDouble('radius') ?? 1000.0;
      _earthquakes = await _usgsService.getRecentEarthquakes(
        timeWindow: timeWindow,
        minMagnitude: minMagnitude,
        radius: radius,
        position: position,
      );
      if (position != null) {
        for (final earthquake in _earthquakes) {
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            earthquake.latitude,
            earthquake.longitude,
          );
          earthquake.distance = distance / 1000; // Convert to kilometers
        }
      }
      _sort();
      _lastUpdated = DateTime.now();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSortCriterion(SortCriterion criterion) {
    _sortCriterion = criterion;
    _sort();
    notifyListeners();
  }

  void _sort() {
    switch (_sortCriterion) {
      case SortCriterion.date:
        _earthquakes.sort((a, b) => b.time.compareTo(a.time));
        break;
      case SortCriterion.magnitude:
        _earthquakes.sort((a, b) => b.magnitude.compareTo(a.magnitude));
        break;
      case SortCriterion.distance:
        _earthquakes.sort((a, b) {
          if (a.distance == null && b.distance == null) return 0;
          if (a.distance == null) return 1;
          if (b.distance == null) return -1;
          return a.distance!.compareTo(b.distance!);
        });
        break;
    }
  }
}
