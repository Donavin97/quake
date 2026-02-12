import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/earthquake.dart';
import '../models/sort_criterion.dart';
import '../services/usgs_service.dart';
import 'settings_provider.dart';

class EarthquakeProvider with ChangeNotifier {
  final UsgsService _usgsService = UsgsService();
  final SettingsProvider _settingsProvider;

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

  EarthquakeProvider(this._settingsProvider) {
    _settingsProvider.addListener(fetchEarthquakes);
  }

  @override
  void dispose() {
    _settingsProvider.removeListener(fetchEarthquakes);
    super.dispose();
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
      _earthquakes = await _usgsService.getRecentEarthquakes(
        timeWindow: _settingsProvider.timeWindow,
        minMagnitude: _settingsProvider.minMagnitude,
        radius: _settingsProvider.radius,
        position: _lastPosition,
      );
      if (_lastPosition != null) {
        for (final earthquake in _earthquakes) {
          final distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
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
