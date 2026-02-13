import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rxdart/rxdart.dart';

import '../models/earthquake.dart';
import '../models/sort_criterion.dart';
import '../services/usgs_service.dart';
import '../services/emsc_service.dart';
import 'settings_provider.dart';

class EarthquakeProvider with ChangeNotifier {
  final UsgsService _usgsService = UsgsService();
  final EmscService _emscService = EmscService();
  late SettingsProvider _settingsProvider;
  StreamSubscription<List<Earthquake>>? _earthquakeSubscription;

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
    _init();
  }

  void _init() {
    _earthquakeSubscription?.cancel();

    Stream<List<Earthquake>>? stream;

    if (_settingsProvider.earthquakeProvider == 'usgs') {
      stream = _usgsService.getEarthquakesStream();
    } else if (_settingsProvider.earthquakeProvider == 'emsc') {
      stream = _emscService.getEarthquakesStream();
    } else if (_settingsProvider.earthquakeProvider == 'both') {
      stream = Rx.combineLatest2(
        _usgsService.getEarthquakesStream(),
        _emscService.getEarthquakesStream(),
        (usgs, emsc) => usgs + emsc,
      );
    }

    if (stream != null) {
      _earthquakeSubscription = stream.listen((earthquakes) {
        _earthquakes = earthquakes;
        _sort();
        _lastUpdated = DateTime.now();
        notifyListeners();
      }, onError: (error) {
        _error = error.toString();
        notifyListeners();
      });
    } else {
        fetchEarthquakes();
    }
  }

  void updateSettings(SettingsProvider newSettings) {
    _settingsProvider = newSettings;
    _init();
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

        if (_settingsProvider.radius > 0) {
          _earthquakes = _earthquakes
              .where((eq) => eq.distance != null && eq.distance! <= _settingsProvider.radius)
              .toList();
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
    _earthquakes.sort((a, b) {
      int comparison;
      switch (_sortCriterion) {
        case SortCriterion.date:
          comparison = b.time.compareTo(a.time);
          break;
        case SortCriterion.magnitude:
          comparison = b.magnitude.compareTo(a.magnitude);
          break;
        case SortCriterion.distance:
          if (a.distance == null && b.distance == null) {
            comparison = 0;
          } else if (a.distance == null) {
            comparison = 1;
          } else if (b.distance == null) {
            comparison = -1;
          } else {
            comparison = a.distance!.compareTo(b.distance!);
          }
          break;
      }
      if (comparison == 0) {
        return b.time.compareTo(a.time);      } else {
        return comparison;
      }
    });
  }

  @override
  void dispose() {
    _earthquakeSubscription?.cancel();
    super.dispose();
  }
}
