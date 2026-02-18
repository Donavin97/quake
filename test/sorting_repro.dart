import 'package:flutter_test/flutter_test.dart';
import 'package:quaketrack/models/earthquake.dart';
import 'package:quaketrack/models/sort_criterion.dart';
import 'package:quaketrack/models/time_window.dart';
import 'package:geolocator/geolocator.dart';

// Mock params
class ProcessingParams {
  final List<Earthquake> earthquakes;
  final Position? userPosition;
  final TimeWindow timeWindow;
  final int minMagnitude;
  final SortCriterion sortCriterion;

  ProcessingParams({
    required this.earthquakes,
    required this.userPosition,
    required this.timeWindow,
    required this.minMagnitude,
    required this.sortCriterion,
  });
}

// Logic copied from EarthquakeProvider._backgroundProcessor
List<Earthquake> backgroundProcessor(ProcessingParams params) {
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
      eq.distance = double.maxFinite;
    }
  }

  // 2. Filter
  list = list.where((eq) {
    final diff = now.difference(eq.time).inDays;
    if (params.timeWindow == TimeWindow.day && diff > 1) return false;
    if (params.timeWindow == TimeWindow.week && diff > 7) return false;
    if (params.timeWindow == TimeWindow.month && diff > 30) return false;

    if (eq.magnitude < params.minMagnitude) return false;

    return true;
  }).toList();

  // 3. Sort
  list.sort((a, b) {
    int comparison;
    // NOTE: In the original code, 'comparison' is declared but not initialized.
    // Dart's definite assignment analysis should catch this if a case is missed.
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
      // Default case is implicit if enum is exhaustive
    }
    // If we reach here and comparison is unassigned, it's a compile error.
    // But if we simulate a runtime where it wasn't assigned (e.g. switch fallthrough issue), we might have issues.
    // However, let's assume it compiles.
    return comparison == 0 ? b.time.compareTo(a.time) : comparison;
  });

  return list;
}

void main() {
  group('Sorting Logic', () {
    final now = DateTime.now();
    
    // Create dummy earthquakes
    final eqNewSmall = Earthquake(
      id: '1', magnitude: 2.0, place: 'A', time: now, 
      latitude: 0, longitude: 0, source: EarthquakeSource.usgs, provider: 'USGS', depth: 10
    );
    final eqOldBig = Earthquake(
      id: '2', magnitude: 8.0, place: 'B', time: now.subtract(const Duration(days: 1)), 
      latitude: 10, longitude: 10, source: EarthquakeSource.usgs, provider: 'USGS', depth: 10
    );
    final eqMidMid = Earthquake(
      id: '3', magnitude: 5.0, place: 'C', time: now.subtract(const Duration(hours: 12)), 
      latitude: 5, longitude: 5, source: EarthquakeSource.usgs, provider: 'USGS', depth: 10
    );

    final allQuakes = [eqNewSmall, eqOldBig, eqMidMid];
    // User at (0,0). 
    // eqNewSmall distance ~0.
    // eqMidMid distance ~700km.
    // eqOldBig distance ~1500km.
    final userPos = Position(latitude: 0, longitude: 0, timestamp: now, accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0);

    test('Sort by Magnitude (Descending)', () {
      final params = ProcessingParams(
        earthquakes: allQuakes,
        userPosition: userPos,
        timeWindow: TimeWindow.month,
        minMagnitude: 0,
        sortCriterion: SortCriterion.magnitude,
      );
      
      final sorted = backgroundProcessor(params);
      
      expect(sorted.map((e) => e.id).toList(), equals(['2', '3', '1'])); // 8.0, 5.0, 2.0
    });

    test('Sort by Date (Newest First)', () {
      final params = ProcessingParams(
        earthquakes: allQuakes,
        userPosition: userPos,
        timeWindow: TimeWindow.month,
        minMagnitude: 0,
        sortCriterion: SortCriterion.date,
      );
      
      final sorted = backgroundProcessor(params);
      
      expect(sorted.map((e) => e.id).toList(), equals(['1', '3', '2'])); // New, Mid, Old
    });

    test('Sort by Distance (Closest First)', () {
      final params = ProcessingParams(
        earthquakes: allQuakes,
        userPosition: userPos,
        timeWindow: TimeWindow.month,
        minMagnitude: 0,
        sortCriterion: SortCriterion.distance,
      );
      
      final sorted = backgroundProcessor(params);
      
      expect(sorted.map((e) => e.id).toList(), equals(['1', '3', '2'])); // 0, ~5, ~10
    });
  });
}
