import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import '../models/earthquake.dart';
import '../models/sort_criterion.dart';
import '../models/time_window.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/geocoding_service.dart'; // Import GeocodingService
import 'location_provider.dart';
import 'settings_provider.dart';

/// Data class to pass parameters to the background Isolate
class _ProcessingParams {
  final List<Earthquake> earthquakes;
  final Position? userPosition;
  final TimeWindow timeWindow;
  final int minMagnitude;
  final SortCriterion sortCriterion;
  final String selectedProvider;
  final double listRadius;

  _ProcessingParams({
    required this.earthquakes,
    required this.userPosition,
    required this.timeWindow,
    required this.minMagnitude,
    required this.sortCriterion,
    required this.selectedProvider,
    required this.listRadius,
  });
}

class EarthquakeProvider with ChangeNotifier {
  final ApiService _apiService;
  final WebSocketService _webSocketService;
  final LocationProvider _locationProvider;
  final GeocodingService _geocodingService;
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
    this._geocodingService,
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
    _geocodeMissingPlaces();

    final List<Earthquake> newEarthquakesToAdd = []; // Declared here

    try {
      final position = _locationProvider.currentPosition;
      // Fetch based on the larger of notification radius or list radius to ensure both filters have data
      final fetchRadius = (_settingsProvider.radius == 0 || _settingsProvider.listRadius == 0) 
          ? 0.0 
          : (_settingsProvider.radius > _settingsProvider.listRadius ? _settingsProvider.radius : _settingsProvider.listRadius);

      final allEarthquakes = await _apiService.fetchEarthquakes(
        _settingsProvider.earthquakeProvider,
        _settingsProvider.minMagnitude.toDouble(),
        fetchRadius,
        position?.latitude,
        position?.longitude,
        timeWindow: _settingsProvider.timeWindow.name,
      );

      // Merge new data with existing cached data


      final List<Earthquake> earthquakesToUpdate = [];

      for (final earthquakeFromApi in allEarthquakes) {
        final index = _earthquakes.indexWhere((e) => e.id == earthquakeFromApi.id);
        
        if (index == -1) {
          final betterPlace = await _geocodingService.reverseGeocode(
            earthquakeFromApi.latitude, 
            earthquakeFromApi.longitude
          );
          if (betterPlace != null) {
            earthquakeFromApi.place = betterPlace;
          }
          _earthquakes.add(earthquakeFromApi);
          earthquakesToUpdate.add(earthquakeFromApi);
        } else {
          final existing = _earthquakes[index];
          // If the existing one doesn't have our new distance/direction format, try to geocode it
          if (!existing.place.contains(' km ')) {
             final betterPlace = await _geocodingService.reverseGeocode(
              earthquakeFromApi.latitude, 
              earthquakeFromApi.longitude
            );
            if (betterPlace != null) {
              earthquakeFromApi.place = betterPlace;
            }
          } else {
            // Keep the previously geocoded place
            earthquakeFromApi.place = existing.place;
          }
          _earthquakes[index] = earthquakeFromApi;
          earthquakesToUpdate.add(earthquakeFromApi);
        }
      }

      // Add/Update earthquakes in Hive
      if (earthquakesToUpdate.isNotEmpty) {
        await _earthquakeBox.putAll(
          {for (final eq in earthquakesToUpdate) eq.id: eq},
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
    _websocketSubscription = _webSocketService.earthquakeStream.listen((newEarthquake) async {
      // Attempt reverse geocoding for WebSocket earthquakes too
      final betterPlace = await _geocodingService.reverseGeocode(
        newEarthquake.latitude, 
        newEarthquake.longitude
      );
      if (betterPlace != null) {
        newEarthquake.place = betterPlace;
      }
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
        selectedProvider: _settingsProvider.earthquakeProvider,
        listRadius: _settingsProvider.listRadius,
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

    // 1. Filter by Provider
    if (params.selectedProvider != 'all') {
      list = list.where((eq) {
        if (params.selectedProvider == 'usgs') return eq.source == EarthquakeSource.usgs;
        if (params.selectedProvider == 'emsc') return eq.source == EarthquakeSource.emsc;
        if (params.selectedProvider == 'sec') return eq.source == EarthquakeSource.sec;
        if (params.selectedProvider == 'both') {
          return eq.source == EarthquakeSource.usgs || eq.source == EarthquakeSource.emsc;
        }
        return true;
      }).toList();
    }

    // 2. Calculate distances and Basic Filter
    for (final eq in list) {
      if (params.userPosition != null) {
        eq.distance = Geolocator.distanceBetween(
          params.userPosition!.latitude,
          params.userPosition!.longitude,
          eq.latitude,
          eq.longitude,
        );
      } else {
        eq.distance = double.maxFinite;
      }
    }

    list = list.where((eq) {
      // Time window
      final diff = now.difference(eq.time).inDays;
      if (params.timeWindow == TimeWindow.day && diff > 1) return false;
      if (params.timeWindow == TimeWindow.week && diff > 7) return false;
      if (params.timeWindow == TimeWindow.month && diff > 30) return false;

      // Magnitude
      if (eq.magnitude < params.minMagnitude) return false;

      // Distance (Radius)
      if (params.listRadius > 0 && eq.distance != null) {
        if (eq.distance! > (params.listRadius * 1000)) { // listRadius is in km, distance is in meters
          return false;
        }
      }

      return true;
    }).toList();

    // 3. Deduplicate (only across different sources)
    if (params.selectedProvider == 'all' || params.selectedProvider == 'both') {
      // Sort by source priority: USGS (0) > EMSC (1) > SEC (2)
      list.sort((a, b) {
        const priority = {
          EarthquakeSource.usgs: 0,
          EarthquakeSource.emsc: 1,
          EarthquakeSource.sec: 2,
        };
        return (priority[a.source] ?? 3).compareTo(priority[b.source] ?? 3);
      });

      final List<Earthquake> deduplicatedList = [];
      for (final eq in list) {
        bool isDuplicate = false;
        for (final existing in deduplicatedList) {
          // If from same source, it's a distinct event (like an aftershock)
          if (eq.source == existing.source) continue;

          final timeDiff = eq.time.difference(existing.time).inSeconds.abs();
          if (timeDiff < 60) { // 1 minute threshold for cross-provider matching
            final distance = Geolocator.distanceBetween(
              eq.latitude,
              eq.longitude,
              existing.latitude,
              existing.longitude,
            );
            if (distance < 50000) { // 50km threshold
              isDuplicate = true;
              break;
            }
          }
        }
        if (!isDuplicate) {
          deduplicatedList.add(eq);
        }
      }
      list = deduplicatedList;
    }

    // 4. Sort according to user preference
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

  Future<void> _geocodeMissingPlaces() async {
    // We only geocode the most recent 50 to avoid massive API hits on startup
    final listToGeocode = _earthquakes.where((eq) => !eq.place.contains(' km ')).toList();
    listToGeocode.sort((a, b) => b.time.compareTo(a.time));
    
    final targets = listToGeocode.take(50).toList();

    for (final eq in targets) {
      if (!eq.place.contains(' km ')) {
        final betterPlace = await _geocodingService.reverseGeocode(eq.latitude, eq.longitude);
        if (betterPlace != null) {
          eq.place = betterPlace;
          await _earthquakeBox.put(eq.id, eq);
          notifyListeners();
        }
        // Small delay to respect Nominatim rate limit (1 req/sec recommended)
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }
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

