import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import '../models/earthquake.dart';
import '../models/sort_criterion.dart';
import '../models/time_window.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import 'location_provider.dart';
import 'settings_provider.dart';

/// Data class to pass parameters to the background Isolate
class _ProcessingParams {
  final List<Earthquake> earthquakes;
  final Position? userPosition;
  final TimeWindow timeWindow;
  final int minMagnitude;
  final SortCriterion sortCriterion;

  _ProcessingParams({
    required this.earthquakes,
    required this.userPosition,
    required this.timeWindow,
    required this.minMagnitude,
    required this.sortCriterion,
  });
}

class EarthquakeProvider with ChangeNotifier {
  final ApiService _apiService;
  final WebSocketService _webSocketService;
  final LocationProvider _locationProvider;
  late SettingsProvider _settingsProvider;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Earthquake>? _websocketSubscription;
  StreamSubscription<Earthquake>? _fcmSubscription;
  StreamSubscription<BoxEvent>? _boxSubscription;

  List<Earthquake> _earthquakes = [];
  String? _error;
  DateTime? _lastUpdated;
  SortCriterion _sortCriterion = SortCriterion.date;
  late Box<Earthquake> _earthquakeBox;
  bool _isProcessing = false;

  List<Earthquake> get earthquakes => _earthquakes;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  SortCriterion get sortCriterion => _sortCriterion;
  bool get isProcessing => _isProcessing;

  EarthquakeProvider(
    this._apiService,
    this._webSocketService,
    this._settingsProvider,
    this._locationProvider,
  ) {
    _earthquakeBox = Hive.box<Earthquake>('earthquakes');
    _init();
  }


  void _init() async {
    _locationSubscription?.cancel();
    _websocketSubscription?.cancel(); // Cancel previous WebSocket subscription
    _fcmSubscription?.cancel(); // Cancel previous FCM subscription
    _boxSubscription?.cancel(); // Cancel previous box subscription

    // Load initial data from Hive
    _earthquakes = _earthquakeBox.values.toList();
    await _processAndRefresh();

    final List<Earthquake> newEarthquakesToAdd = []; // Declared here

    try {
      final position = _locationProvider.currentPosition;
      final allEarthquakes = await _apiService.fetchEarthquakes(
        _settingsProvider.earthquakeProvider,
        _settingsProvider.minMagnitude.toDouble(),
        _settingsProvider.radius,
        position?.latitude,
        position?.longitude,
      );

      // Merge new data with existing cached data
      final Set<String> existingEarthquakeIds = _earthquakes.map((e) => e.id).toSet();


      for (final earthquakeFromApi in allEarthquakes) {
        if (!existingEarthquakeIds.contains(earthquakeFromApi.id)) {
          newEarthquakesToAdd.add(earthquakeFromApi);
        }
      }

      // Add new earthquakes to the main list and Hive
      if (newEarthquakesToAdd.isNotEmpty) {
        _earthquakes.addAll(newEarthquakesToAdd);
        await _earthquakeBox.putAll(
          {for (final eq in newEarthquakesToAdd) eq.id: eq},
        );
      }

      // Perform background processing
      await _processAndRefresh();
      
      _lastUpdated = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      // Notify listeners only if there were actual changes or new data was fetched
      if (newEarthquakesToAdd.isNotEmpty || _error != null) {
        notifyListeners();
      }
    }

    _locationSubscription = _locationProvider.locationStream.listen((position) {
      _processAndRefresh();
    });

    // Subscribe to WebSocket stream
    _websocketSubscription = _webSocketService.earthquakeStream.listen((newEarthquake) {
      _addNewEarthquake(newEarthquake);
    });

    // Subscribe to Hive box changes (handles background updates and foreground FCM writes)
    _boxSubscription = _earthquakeBox.watch().listen((event) {
      // If the event value is null, it might be a deletion, or we should ignore it if not relevant
      if (event.deleted) {
         _earthquakes.removeWhere((e) => e.id == event.key);
         _processAndRefresh();
      } else if (event.value != null && event.value is Earthquake) {
        final newEq = event.value as Earthquake;
        final index = _earthquakes.indexWhere((e) => e.id == newEq.id);
        if (index != -1) {
          // Update existing
          _earthquakes[index] = newEq;
        } else {
          // Add new
          _earthquakes.add(newEq);
        }
        _processAndRefresh();
        _lastUpdated = DateTime.now();
      }
    });
  }

  /// High-level method to trigger processing
  Future<void> _processAndRefresh() async {
    if (_earthquakes.isEmpty) {
      notifyListeners();
      return;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final params = _ProcessingParams(
        earthquakes: _earthquakes,
        userPosition: _locationProvider.currentPosition,
        timeWindow: _settingsProvider.timeWindow,
        minMagnitude: _settingsProvider.minMagnitude,
        sortCriterion: _sortCriterion,
      );

      // Run directly in main isolate to avoid HiveObject serialization issues
      _earthquakes = _processEarthquakes(params);
      
    } catch (e) {
      debugPrint('Processing error: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Synchronous processor running on main thread
  static List<Earthquake> _processEarthquakes(_ProcessingParams params) {
    List<Earthquake> list = List.from(params.earthquakes);
    final now = DateTime.now();

    // 1. Calculate distances
    for (final eq in list) {
      if (params.userPosition != null) {
        eq.distance = Geolocator.distanceBetween(
          params.userPosition!.latitude,
          params.userPosition!.longitude,
          eq.latitude,
          eq.longitude,
        );
      } else {
        // If user position is null, assign a very large distance
        // so these earthquakes appear at the end when sorting by distance.
        eq.distance = double.maxFinite;
      }
    }

    // 2. Filter
    list = list.where((eq) {
      // Time window
      final diff = now.difference(eq.time).inDays;
      if (params.timeWindow == TimeWindow.day && diff > 1) return false;
      if (params.timeWindow == TimeWindow.week && diff > 7) return false;
      if (params.timeWindow == TimeWindow.month && diff > 30) return false;

      // Magnitude
      if (eq.magnitude < params.minMagnitude) return false;

      return true;
    }).toList();

    // 3. Sort
    list.sort((a, b) {
      int comparison;
      switch (params.sortCriterion) {
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
      return comparison == 0 ? b.time.compareTo(a.time) : comparison;
    });

    return list;
  }

  void _addNewEarthquake(Earthquake newEarthquake) async {
    // Prevent duplicates
    if (!_earthquakes.any((eq) => eq.id == newEarthquake.id)) {
      _earthquakes.add(newEarthquake);
      await _earthquakeBox.put(newEarthquake.id, newEarthquake);
      await _processAndRefresh();
      _lastUpdated = DateTime.now();
    }
  }

  void refresh() {
    _init();
  }

  void updateSettings(SettingsProvider newSettings) {
    _settingsProvider = newSettings;
    _init();
  }

  void setSortCriterion(SortCriterion criterion) {
    _sortCriterion = criterion;
    _processAndRefresh();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _websocketSubscription?.cancel();
    _boxSubscription?.cancel();
    super.dispose();
  }
}

