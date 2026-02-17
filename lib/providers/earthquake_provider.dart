import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import '../models/earthquake.dart';
import '../models/sort_criterion.dart';
import '../models/time_window.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart'; // Import WebSocketService
import 'location_provider.dart';
import 'settings_provider.dart';

class EarthquakeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final WebSocketService _webSocketService = WebSocketService(); // Instantiate WebSocketService
  final LocationProvider _locationProvider;
  late SettingsProvider _settingsProvider;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Earthquake>? _websocketSubscription; // Add WebSocket subscription

  List<Earthquake> _earthquakes = [];
  String? _error;
  DateTime? _lastUpdated;
  SortCriterion _sortCriterion = SortCriterion.date;
  late Box<Earthquake> _earthquakeBox;

  List<Earthquake> get earthquakes => _earthquakes;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  SortCriterion get sortCriterion => _sortCriterion;

  EarthquakeProvider(this._settingsProvider, this._locationProvider) {
    _earthquakeBox = Hive.box<Earthquake>('earthquakes');
    _init();
  }

  void _init() async {
    _locationSubscription?.cancel();
    _websocketSubscription?.cancel(); // Cancel previous WebSocket subscription

    // Load initial data from Hive
    _earthquakes = _earthquakeBox.values.toList();
    _updateDistances();
    _sort();
    notifyListeners();

    try {
      final position = _locationProvider.currentPosition;
      final allEarthquakes = await _apiService.fetchEarthquakes(
        _settingsProvider.earthquakeProvider,
        _settingsProvider.minMagnitude.toDouble(),
        _settingsProvider.radius,
        position?.latitude,
        position?.longitude,
      );

      _earthquakes = _filterEarthquakes(allEarthquakes);

      // Update Hive box
      await _earthquakeBox.clear();
      await _earthquakeBox.addAll(_earthquakes);

      _updateDistances();
      _sort();
      _lastUpdated = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }

    _locationSubscription = _locationProvider.locationStream.listen((position) {
      _updateDistances();
      _sort();
      notifyListeners();
    });

    // Subscribe to WebSocket stream
    _websocketSubscription = _webSocketService.earthquakeStream.listen((newEarthquake) {
      _addNewEarthquake(newEarthquake);
    });
  }

  void _addNewEarthquake(Earthquake newEarthquake) async {
    // Prevent duplicates
    if (!_earthquakes.any((eq) => eq.id == newEarthquake.id)) {
      _earthquakes.add(newEarthquake);
      _updateDistances();
      _earthquakes = _filterEarthquakes(_earthquakes); // Apply filters to the new earthquake
      _sort();
      await _earthquakeBox.put(newEarthquake.id, newEarthquake); // Add to Hive
      _lastUpdated = DateTime.now(); // Update last updated time
      notifyListeners();
    }
  }

  void refresh() {
    _init();
  }

  List<Earthquake> _filterEarthquakes(List<Earthquake> earthquakes) {
    return earthquakes.where((earthquake) {
      final timeWindow = _settingsProvider.timeWindow;
      final now = DateTime.now();

      // Time window filter
      if (timeWindow == TimeWindow.day &&
          now.difference(earthquake.time).inDays > 1) {
        return false;
      }
      if (timeWindow == TimeWindow.week &&
          now.difference(earthquake.time).inDays > 7) {
        return false;
      }
      if (timeWindow == TimeWindow.month &&
          now.difference(earthquake.time).inDays > 30) {
        return false;
      }

      // Magnitude filter (from settings provider)
      if (earthquake.magnitude < _settingsProvider.minMagnitude) {
        return false;
      }
      return true;
    }).toList();
  }

  void _updateDistances() {
    final position = _locationProvider.currentPosition;
    if (position != null) {
      for (final earthquake in _earthquakes) {
        earthquake.distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          earthquake.latitude,
          earthquake.longitude,
        );
      }
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
        return b.time.compareTo(a.time);
      } else {
        return comparison;
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _websocketSubscription?.cancel(); // Cancel WebSocket subscription
    _webSocketService.dispose(); // Dispose WebSocketService
    super.dispose();
  }
}
