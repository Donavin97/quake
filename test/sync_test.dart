import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quaketrack/models/earthquake.dart';
import 'package:quaketrack/models/time_window.dart';
import 'package:quaketrack/providers/earthquake_provider.dart';
import 'package:quaketrack/providers/location_provider.dart';
import 'package:quaketrack/providers/safety_provider.dart';
import 'package:quaketrack/providers/service_providers.dart';
import 'package:quaketrack/repositories/earthquake_repository.dart';
import 'package:quaketrack/services/api_service.dart';
import 'package:quaketrack/services/geocoding_service.dart';
import 'package:quaketrack/services/websocket_service.dart';
import 'package:quaketrack/services/location_service.dart';

import 'sync_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ApiService>(),
  MockSpec<WebSocketService>(),
  MockSpec<GeocodingService>(),
  MockSpec<LocationService>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late MockApiService mockApiService;
  late MockWebSocketService mockWebSocketService;
  late MockGeocodingService mockGeocodingService;
  late MockLocationService mockLocationService;

  setUp(() {
    mockApiService = MockApiService();
    mockWebSocketService = MockWebSocketService();
    mockGeocodingService = MockGeocodingService();
    mockLocationService = MockLocationService();

    when(mockWebSocketService.earthquakeStream).thenAnswer((_) => const Stream.empty());
    when(mockLocationService.checkPermission()).thenAnswer((_) async => LocationPermission.always);

    SharedPreferences.setMockInitialValues({});

    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
        webSocketServiceProvider.overrideWithValue(mockWebSocketService),
        geocodingServiceProvider.overrideWithValue(mockGeocodingService),
        locationServiceProvider.overrideWithValue(mockLocationService),
        earthquakeRepositoryProvider.overrideWithValue(
          EarthquakeRepository(mockApiService, mockGeocodingService),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Safety Notifier Threat Detection', () {
    test('Should not trigger threat for minor earthquake far away', () async {
      // Build safety provider first to start listening
      container.read(safetyProvider);

      final quake = Earthquake(
        id: '1',
        magnitude: 3.0,
        place: 'Test',
        time: DateTime.now(),
        latitude: 0.0,
        longitude: 0.0,
        source: EarthquakeSource.usgs,
        provider: 'USGS',
        depth: 10.0,
      );

      container.read(locationProvider.notifier).state = LocationState(
        position: Position(
          latitude: 5.0,
          longitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
        permissionGranted: true,
      );

      container.read(earthquakeNotifierProvider.notifier).state = EarthquakeState(
        allEarthquakes: [quake],
      );

      expect(container.read(safetyProvider).pendingSafetyCheck, isNull);
    });

    test('Should trigger threat for M5.0+ within 100km', () async {
      container.read(safetyProvider);

      final quake = Earthquake(
        id: 'threat_1',
        magnitude: 5.5,
        place: 'Near User',
        time: DateTime.now(),
        latitude: 0.0,
        longitude: 0.0,
        source: EarthquakeSource.usgs,
        provider: 'USGS',
        depth: 10.0,
      );

      container.read(locationProvider.notifier).state = LocationState(
        position: Position(
          latitude: 0.1,
          longitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
        permissionGranted: true,
      );

      container.read(earthquakeNotifierProvider.notifier).state = EarthquakeState(
        allEarthquakes: [quake],
      );

      expect(container.read(safetyProvider).pendingSafetyCheck?.id, equals('threat_1'));
    });

    test('Should trigger threat for M7.0+ within 300km', () async {
      container.read(safetyProvider);

      final quake = Earthquake(
        id: 'major_threat',
        magnitude: 7.2,
        place: 'Regionally Near',
        time: DateTime.now(),
        latitude: 0.0,
        longitude: 0.0,
        source: EarthquakeSource.usgs,
        provider: 'USGS',
        depth: 10.0,
      );

      // Set user location at ~220km distance
      container.read(locationProvider.notifier).state = LocationState(
        position: Position(
          latitude: 2.0,
          longitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
        permissionGranted: true,
      );

      container.read(earthquakeNotifierProvider.notifier).state = EarthquakeState(
        allEarthquakes: [quake],
      );

      expect(container.read(safetyProvider).pendingSafetyCheck?.id, equals('major_threat'));
    });

    test('Should not trigger twice for same earthquake ID', () async {
      container.read(safetyProvider);

      final quake = Earthquake(
        id: 'dup_test',
        magnitude: 8.0,
        place: 'Big One',
        time: DateTime.now(),
        latitude: 0.0,
        longitude: 0.0,
        source: EarthquakeSource.usgs,
        provider: 'USGS',
        depth: 10.0,
      );

      container.read(locationProvider.notifier).state = LocationState(
        position: Position(
          latitude: 0.0,
          longitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
        permissionGranted: true,
      );

      container.read(earthquakeNotifierProvider.notifier).state = EarthquakeState(
        allEarthquakes: [quake],
      );
      
      expect(container.read(safetyProvider).pendingSafetyCheck?.id, equals('dup_test'));

      container.read(safetyProvider.notifier).ignore();
      expect(container.read(safetyProvider).pendingSafetyCheck, isNull);

      container.read(earthquakeNotifierProvider.notifier).state = EarthquakeState(
        allEarthquakes: [quake],
      );

      expect(container.read(safetyProvider).pendingSafetyCheck, isNull);
    });
  });

  group('EarthquakeRepository Sync', () {
    test('Sync should add new earthquakes and preserve geocoded names', () async {
      final repository = container.read(earthquakeRepositoryProvider);
      
      final existingQuake = Earthquake(
        id: 'existing',
        magnitude: 4.0,
        place: 'Geocoded City Name', // Generic was "10km S of..."
        time: DateTime.now().subtract(const Duration(hours: 1)),
        latitude: 0.0,
        longitude: 0.0,
        source: EarthquakeSource.usgs,
        provider: 'USGS',
        depth: 10.0,
      );

      final apiQuakeGeneric = Earthquake(
        id: 'existing',
        magnitude: 4.0,
        place: '10km S of Somewhere', // API returns generic name
        time: existingQuake.time,
        latitude: 0.0,
        longitude: 0.0,
        source: EarthquakeSource.usgs,
        provider: 'USGS',
        depth: 10.0,
      );

      final newQuake = Earthquake(
        id: 'new',
        magnitude: 5.0,
        place: 'New Place',
        time: DateTime.now(),
        latitude: 1.0,
        longitude: 1.0,
        source: EarthquakeSource.usgs,
        provider: 'USGS',
        depth: 10.0,
      );

      // Pre-populate via SharedPreferences
      SharedPreferences.setMockInitialValues({
        'cached_earthquakes': jsonEncode([existingQuake.toJson()]),
      });
      await repository.loadCache();

      when(mockApiService.fetchEarthquakes(any, any, any, any, any, timeWindow: anyNamed('timeWindow')))
          .thenAnswer((_) async => [apiQuakeGeneric, newQuake]);

      await repository.sync(
        provider: 'usgs',
        minMagnitude: 2.0,
        radius: 0,
        latitude: 0,
        longitude: 0,
        timeWindow: TimeWindow.day,
      );

      // Verify repository state
      final currentQuakes = repository.allEarthquakes;
      expect(currentQuakes.length, equals(2));
      
      final updatedExisting = currentQuakes.firstWhere((e) => e.id == 'existing');
      expect(updatedExisting.place, equals('Geocoded City Name'));

      final addedNew = currentQuakes.firstWhere((e) => e.id == 'new');
      expect(addedNew.id, equals('new'));
    });

    test('Sync should remove old earthquakes that are no longer in API but match filter', () async {
      final repository = container.read(earthquakeRepositoryProvider);
      
      final staleQuake = Earthquake(
        id: 'stale',
        magnitude: 6.0,
        place: 'Old Quake',
        time: DateTime.now().subtract(const Duration(minutes: 30)),
        latitude: 0.0,
        longitude: 0.0,
        source: EarthquakeSource.usgs,
        provider: 'USGS',
        depth: 10.0,
      );

      // Pre-populate
      SharedPreferences.setMockInitialValues({
        'cached_earthquakes': jsonEncode([staleQuake.toJson()]),
      });
      await repository.loadCache();

      when(mockApiService.fetchEarthquakes(any, any, any, any, any, timeWindow: anyNamed('timeWindow')))
          .thenAnswer((_) async => []); // API no longer returns it

      await repository.sync(
        provider: 'usgs',
        minMagnitude: 2.0,
        radius: 0,
        latitude: 0,
        longitude: 0,
        timeWindow: TimeWindow.day,
      );

      // Should have been removed
      expect(repository.allEarthquakes.any((e) => e.id == 'stale'), isFalse);
    });
  });
}
