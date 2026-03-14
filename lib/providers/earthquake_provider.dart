import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/earthquake.dart';
import '../models/sort_criterion.dart';
import '../models/time_window.dart';
import '../models/notification_profile.dart';
import 'location_provider.dart';
import 'settings_provider.dart';
import 'service_providers.dart';

part 'earthquake_provider.freezed.dart';
part 'earthquake_provider.g.dart';

@freezed
class EarthquakeState with _$EarthquakeState {
  const factory EarthquakeState({
    @Default([]) List<Earthquake> allEarthquakes,
    @Default([]) List<Earthquake> displayEarthquakes,
    @Default([]) List<Earthquake> archiveEarthquakes,
    String? error,
    DateTime? lastUpdated,
    @Default(SortCriterion.date) SortCriterion sortCriterion,
    @Default(false) bool isProcessing,
    @Default(false) bool isInitializing,
    @Default(false) bool isSearchingArchive,
    @Default(false) bool isArchiveMode,
    NotificationProfile? filterNotificationProfile,
  }) = _EarthquakeState;
}

class _ProcessingParams {
  final List<Earthquake> earthquakes;
  final Position? userPosition;
  final TimeWindow timeWindow;
  final double minMagnitude;
  final SortCriterion sortCriterion;
  final String selectedProvider;
  final double listRadius;
  final double latitude;
  final double longitude;

  _ProcessingParams({
    required this.earthquakes,
    required this.userPosition,
    required this.timeWindow,
    required this.minMagnitude,
    required this.sortCriterion,
    required this.selectedProvider,
    required this.listRadius,
    required this.latitude,
    required this.longitude,
  });
}

@riverpod
class EarthquakeNotifier extends _$EarthquakeNotifier {
  StreamSubscription? _websocketSubscription;
  StreamSubscription? _boxSubscription;
  Timer? _debounceTimer;
  bool _fetchRequestedWhileInitializing = false;

  @override
  EarthquakeState build() {
    final repository = ref.read(earthquakeRepositoryProvider);
    final webSocketService = ref.read(webSocketServiceProvider);

    // Watch settings to react to profile/preference changes
    ref.listen(settingsProvider, (previous, next) {
      if (!next.isLoaded) return;
      
      final nextProfile = next.activeNotificationProfile ?? 
          next.userPreferences.notificationProfiles.firstOrNull;
      
      if (previous == null || !previous.isLoaded || state.filterNotificationProfile != nextProfile) {
        state = state.copyWith(filterNotificationProfile: nextProfile);
        _fetchNewData();
      } else {
        _processAndRefresh();
      }
    });

    ref.onDispose(() {
      _websocketSubscription?.cancel();
      _boxSubscription?.cancel();
      _debounceTimer?.cancel();
    });

    _websocketSubscription = webSocketService.earthquakeStream.listen((newEq) {
      _addNewEarthquake(newEq);
    });

    // OPTIMIZATION: Debounced listener for background or external box changes
    // This prevents "flicker" during massive batch updates
    _boxSubscription = repository.watch().listen((_) {
      _debounceRefreshFromRepository();
    });

    // Initial state with local data
    final settings = ref.read(settingsProvider);
    final initialProfile = settings.activeNotificationProfile ?? 
        settings.userPreferences.notificationProfiles.firstOrNull;

    if (settings.isLoaded) {
      Future.microtask(() => _fetchNewData());
    }
    
    // Load cache from SharedPreferences
    Future.microtask(() => repository.loadCache());

    return EarthquakeState(
      allEarthquakes: repository.allEarthquakes,
      filterNotificationProfile: initialProfile,
    );
  }

  void _debounceRefreshFromRepository() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _refreshFromRepository();
    });
  }

  void _refreshFromRepository() {
    final repository = ref.read(earthquakeRepositoryProvider);
    state = state.copyWith(allEarthquakes: repository.allEarthquakes);
    _processAndRefresh();
  }

  Future<void> _fetchNewData() async {
    if (state.isInitializing) {
      _fetchRequestedWhileInitializing = true;
      return;
    }

    state = state.copyWith(isInitializing: true);

    try {
      final repository = ref.read(earthquakeRepositoryProvider);
      final settings = ref.read(settingsProvider);
      final locationState = ref.read(locationProvider);

      while (true) {
        _fetchRequestedWhileInitializing = false;
        
        final profile = state.filterNotificationProfile;
        if (profile == null) break;

        final currentPos = locationState.position;
        final double effectiveLat = (profile.latitude != 0.0 || profile.longitude != 0.0)
            ? profile.latitude
            : (currentPos?.latitude ?? 0.0);
        final double effectiveLon = (profile.latitude != 0.0 || profile.longitude != 0.0)
            ? profile.longitude
            : (currentPos?.longitude ?? 0.0);

        // OPTIMIZATION: Use the returned list directly to avoid redundant Hive reads
        final updatedList = await repository.sync(
          provider: settings.earthquakeProvider,
          minMagnitude: profile.minMagnitude,
          radius: profile.radius,
          latitude: effectiveLat,
          longitude: effectiveLon,
          timeWindow: settings.timeWindow,
        );

        state = state.copyWith(
          allEarthquakes: updatedList,
          lastUpdated: DateTime.now(),
          error: null,
        );
        
        await _processAndRefresh(immediate: true);

        if (!_fetchRequestedWhileInitializing) break;
      }
    } catch (e) {
      debugPrint('Fetch failed: $e');
      state = state.copyWith(error: 'Showing offline data. Check connection.');
    } finally {
      state = state.copyWith(isInitializing: false);
      _fetchRequestedWhileInitializing = false;
    }
  }

  Future<void> _processAndRefresh({bool immediate = false}) async {
    if (state.isProcessing) return;

    if (!immediate) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _processAndRefresh(immediate: true);
      });
      return;
    }

    if (state.allEarthquakes.isEmpty) {
      state = state.copyWith(displayEarthquakes: [], isProcessing: false);
      return;
    }

    state = state.copyWith(isProcessing: true);

    try {
      final locationState = ref.read(locationProvider);
      final settings = ref.read(settingsProvider);
      final profile = state.filterNotificationProfile;
      
      if (profile == null) {
        state = state.copyWith(isProcessing: false);
        return;
      }

      final currentPos = locationState.position;
      final double effectiveLat = (profile.latitude != 0.0 || profile.longitude != 0.0)
          ? profile.latitude
          : (currentPos?.latitude ?? 0.0);
      final double effectiveLon = (profile.latitude != 0.0 || profile.longitude != 0.0)
          ? profile.longitude
          : (currentPos?.longitude ?? 0.0);

      final params = _ProcessingParams(
        earthquakes: state.allEarthquakes,
        userPosition: currentPos,
        timeWindow: settings.timeWindow,
        minMagnitude: profile.minMagnitude,
        sortCriterion: state.sortCriterion,
        selectedProvider: settings.earthquakeProvider,
        listRadius: profile.radius,
        latitude: effectiveLat,
        longitude: effectiveLon,
      );

      final processedList = await compute(_processEarthquakes, params);
      state = state.copyWith(displayEarthquakes: processedList, isProcessing: false);
    } catch (e) {
      debugPrint('Processing error: $e');
      state = state.copyWith(isProcessing: false);
    }
  }

  static List<Earthquake> _processEarthquakes(_ProcessingParams params) {
    List<Earthquake> list = List.from(params.earthquakes);
    final now = DateTime.now().toUtc();

    if (params.selectedProvider != 'all') {
      list = list.where((eq) {
        if (params.selectedProvider == 'usgs') return eq.source == EarthquakeSource.usgs;
        if (params.selectedProvider == 'emsc') return eq.source == EarthquakeSource.emsc;
        if (params.selectedProvider == 'sec') return eq.source == EarthquakeSource.sec;
        return true;
      }).toList();
    }

    for (final eq in list) {
      eq.filterDistance = Geolocator.distanceBetween(
        params.latitude,
        params.longitude,
        eq.latitude,
        eq.longitude,
      );

      if (params.userPosition != null) {
        eq.distance = Geolocator.distanceBetween(
          params.userPosition!.latitude,
          params.userPosition!.longitude,
          eq.latitude,
          eq.longitude,
        );
      } else {
        eq.distance = eq.filterDistance;
      }
    }

    list = list.where((eq) {
      final diffInHours = now.difference(eq.time).inHours;
      if (params.timeWindow == TimeWindow.day && diffInHours > 24) return false;
      if (params.timeWindow == TimeWindow.week && diffInHours > 168) return false;
      if (params.timeWindow == TimeWindow.month && diffInHours > 720) return false;

      if (eq.magnitude < params.minMagnitude) return false;

      if (params.listRadius > 0 && eq.filterDistance != null) {
        if (eq.filterDistance! > (params.listRadius * 1000)) {
          return false;
        }
      }

      return true;
    }).toList();

    if (params.selectedProvider == 'all') {
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
          if (eq.source == existing.source) continue;
          final timeDiff = eq.time.difference(existing.time).inSeconds.abs();
          if (timeDiff < 60) {
            final distance = Geolocator.distanceBetween(
              eq.latitude,
              eq.longitude,
              existing.latitude,
              existing.longitude,
            );
            if (distance < 50000) {
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

  void _addNewEarthquake(Earthquake newEq) async {
    if (!state.allEarthquakes.any((eq) => eq.id == newEq.id)) {
      final repository = ref.read(earthquakeRepositoryProvider);
      await repository.addEarthquake(newEq);
      // The box listener will trigger the refresh automatically
    }
  }

  void setFilterProfile(NotificationProfile profile) {
    state = state.copyWith(filterNotificationProfile: profile);
    _fetchNewData();
  }

  void refresh() {
    _fetchNewData();
  }

  void setSortCriterion(SortCriterion criterion) {
    state = state.copyWith(sortCriterion: criterion);
    _processAndRefresh();
  }

  void toggleArchiveMode(bool enabled) {
    state = state.copyWith(isArchiveMode: enabled);
    if (!enabled) {
      state = state.copyWith(archiveEarthquakes: []);
    }
  }

  Future<void> searchGlobalArchive(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(archiveEarthquakes: []);
      return;
    }

    state = state.copyWith(isSearchingArchive: true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final locationState = ref.read(locationProvider);
      
      final results = await apiService.fetchEarthquakes('all', 2.0, 0, 0, 0, timeWindow: 'month');

      final queryLower = query.toLowerCase();
      final archive = results.where((eq) {
        return eq.place.toLowerCase().contains(queryLower) ||
               eq.id.toLowerCase().contains(queryLower) ||
               eq.provider.toLowerCase().contains(queryLower);
      }).toList();

      archive.sort((a, b) => b.time.compareTo(a.time));
      
      final currentPos = locationState.position;
      if (currentPos != null) {
        for (final eq in archive) {
          eq.distance = Geolocator.distanceBetween(
            currentPos.latitude,
            currentPos.longitude,
            eq.latitude,
            eq.longitude,
          );
        }
      }
      state = state.copyWith(archiveEarthquakes: archive);
    } catch (e) {
      state = state.copyWith(error: 'Archive search failed. Check connection.');
    } finally {
      state = state.copyWith(isSearchingArchive: false);
    }
  }
}
