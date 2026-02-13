import 'dart:async';

import 'package:flutter/material.dart';
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
  String? _error;
  DateTime? _lastUpdated;
  SortCriterion _sortCriterion = SortCriterion.date;

  List<Earthquake> get earthquakes => _earthquakes;
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
      stream = _usgsService.getEarthquakesStream(_settingsProvider);
    } else if (_settingsProvider.earthquakeProvider == 'emsc') {
      stream = _emscService.getEarthquakesStream(_settingsProvider);
    } else if (_settingsProvider.earthquakeProvider == 'both') {
      stream = Rx.combineLatest2(
        _usgsService.getEarthquakesStream(_settingsProvider),
        _emscService.getEarthquakesStream(_settingsProvider),
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
    }
  }

  void updateSettings(SettingsProvider newSettings) {
    _settingsProvider = newSettings;
    _init();
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
