import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/earthquake.dart';
import '../models/time_window.dart';
import '../services/api_service.dart';
import '../services/geocoding_service.dart';

class EarthquakeRepository {
  final ApiService _apiService;
  final GeocodingService _geocodingService;
  
  List<Earthquake> _earthquakes = [];
  final _controller = StreamController<void>.broadcast(); // Broadcasting "void" just to signal change, similar to BoxEvent, or send List?
  // The original exposed Stream<BoxEvent>. The provider listened and called _refreshFromRepository.
  // So a simple void stream is enough to trigger refresh.
  
  EarthquakeRepository(this._apiService, this._geocodingService);

  List<Earthquake> get allEarthquakes => List.unmodifiable(_earthquakes);

  Stream<void> watch() => _controller.stream;

  Future<void> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cached_earthquakes');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _earthquakes = jsonList.map((e) => Earthquake.fromJson(e)).toList();
        _controller.add(null);
      }
    } catch (e) {
      debugPrint('Error loading earthquake cache: $e');
    }
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _earthquakes.map((e) => e.toJson()).toList();
      await prefs.setString('cached_earthquakes', jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving earthquake cache: $e');
    }
  }

  /// Syncs local data with the API. Returns the final updated list of all earthquakes.
  Future<List<Earthquake>> sync({
    required String provider,
    required double minMagnitude,
    required double radius,
    required double latitude,
    required double longitude,
    required TimeWindow timeWindow,
  }) async {
    try {
      // 1. Fetch fresh data from API
      final List<Earthquake> apiResults = await _apiService.fetchEarthquakes(
        provider,
        minMagnitude,
        radius,
        latitude,
        longitude,
        timeWindow: timeWindow.name,
      );

      final Map<String, Earthquake> currentMap = {for (final e in _earthquakes) e.id: e};
      final now = DateTime.now().toUtc();

      // 2. Merge logic
      // We want to keep existing quakes that are NOT in API result ONLY if they shouldn't have been returned (e.g. out of filter).
      // But if they SHOULD be in result and aren't, they are stale/deleted.
      // Actually, the original logic was:
      // "Identify stale local quakes... If inMagnitude && inRadius && inTime -> Remove"
      
      // Let's replicate the logic but on the list.
      
      final Set<String> apiIds = apiResults.map((e) => e.id).toSet();
      final List<String> idsToRemove = [];

      for (final localEq in _earthquakes) {
        if (apiIds.contains(localEq.id)) continue;

        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          localEq.latitude,
          localEq.longitude,
        );
        
        final inMagnitude = localEq.magnitude >= minMagnitude;
        final inRadius = radius == 0 || distance <= (radius * 1000);
        final diff = now.difference(localEq.time).inDays;
        final inTime = (timeWindow == TimeWindow.day && diff <= 1) ||
                       (timeWindow == TimeWindow.week && diff <= 7) ||
                       (timeWindow == TimeWindow.month && diff <= 30);

        if (inMagnitude && inRadius && inTime) {
          idsToRemove.add(localEq.id);
        }
      }

      // Remove stale
      currentMap.removeWhere((id, _) => idsToRemove.contains(id));

      // Add/Update new
      for (final eqApi in apiResults) {
        final localEq = currentMap[eqApi.id];
        if (localEq != null) {
          // Preserve geocoding
          final isApiGeneric = eqApi.place.toLowerCase().contains('km');
          final isLocalGeneric = localEq.place.toLowerCase().contains('km');
          if (isApiGeneric && !isLocalGeneric) {
            eqApi.place = localEq.place;
          }
        }
        currentMap[eqApi.id] = eqApi;
      }

      _earthquakes = currentMap.values.toList();
      _controller.add(null); // Notify listeners
      await _saveCache();

      return _earthquakes;
    } catch (e) {
      debugPrint('Repository Sync Error: $e');
      rethrow;
    }
  }

  Future<String?> geocode(Earthquake eq) async {
    final betterPlace = await _geocodingService.reverseGeocode(eq.latitude, eq.longitude);
    if (betterPlace != null && betterPlace != eq.place) {
      eq.place = betterPlace;
      
      // Update in local list
      final index = _earthquakes.indexWhere((e) => e.id == eq.id);
      if (index != -1) {
        _earthquakes[index] = eq; // Update reference? Earthquake is immutable, but we modified 'place' field? 
        // Wait, Earthquake 'place' field is NOT final in my modification.
        // So eq.place = betterPlace works.
        // But we should save cache.
        _controller.add(null);
        await _saveCache();
      }
      
      return betterPlace;
    }
    return null;
  }

  Future<void> addEarthquake(Earthquake eq) async {
    if (!_earthquakes.any((e) => e.id == eq.id)) {
      _earthquakes.add(eq);
      _controller.add(null);
      await _saveCache();
    }
  }

  Future<void> deleteEarthquake(String id) async {
    _earthquakes.removeWhere((e) => e.id == id);
    _controller.add(null);
    await _saveCache();
  }
}
