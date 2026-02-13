
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/earthquake.dart';
import '../models/sort_criterion.dart';
import '../services/usgs_service.dart';
import '../services/emsc_service.dart';
import 'settings_provider.dart';

class EarthquakeProvider with ChangeNotifier {
  final UsgsService _usgsService = UsgsService();
  final EmscService _emscService = EmscService();
  SettingsProvider _settingsProvider;

  List<Earthquake> _earthquakes = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;
  SortCriterion _sortCriterion = SortCriterion.date;
  Position? _lastPosition;

  List<Earthquake> get earthquakes => _earthquakes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  SortCriterion get sortCriterion => _sortCriterion;

  EarthquakeProvider(this._settingsProvider);

  void updateSettings(SettingsProvider newSettings) {
    _settingsProvider = newSettings;
    fetchEarthquakes();
  }

  Future<void> fetchEarthquakes({Position? position}) async {
    if (position != null) {
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (distance < 10000) { // 10 kilometers
          return;
        }
      }
      _lastPosition = position;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<Earthquake> allEarthquakes;
      if (_settingsProvider.earthquakeProvider == 'usgs') {
        allEarthquakes = await _usgsService.getRecentEarthquakes(
          timeWindow: _settingsProvider.timeWindow,
          minMagnitude: _settingsProvider.minMagnitude,
        );
      } else {
        allEarthquakes = await _emscService.fetchEarthquakes();
      }

      if (_lastPosition != null) {
        for (final earthquake in allEarthquakes) {
          final distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            earthquake.latitude,
            earthquake.longitude,
          );
          earthquake.distance = distance / 1000; // Convert to kilometers
        }

        if (_settingsProvider.radius > 0) {
          _earthquakes = allEarthquakes
              .where((eq) => eq.distance != null && eq.distance! <= _settingsProvider.radius)
              .toList();
        } else {
          _earthquakes = allEarthquakes;
        }
      } else {
        _earthquakes = allEarthquakes;
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
