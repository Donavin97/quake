import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'service_providers.dart';

part 'location_provider.freezed.dart';
part 'location_provider.g.dart';

@freezed
class LocationState with _$LocationState {
  const factory LocationState({
    Position? position,
    String? countryCode,
    @Default(false) bool permissionGranted,
    String? error,
    @Default(false) bool isLoading,
  }) = _LocationState;
}

@riverpod
class Location extends _$Location {
  final StreamController<Position> _locationStreamController = StreamController<Position>.broadcast();

  Stream<Position> get locationStream => _locationStreamController.stream;

  @override
  LocationState build() {
    ref.onDispose(() {
      _locationStreamController.close();
    });
    _checkInitialPermission();
    return const LocationState();
  }

  Future<void> _checkInitialPermission() async {
    final locationService = ref.read(locationServiceProvider);
    final permission = await locationService.checkPermission();
    state = state.copyWith(
      permissionGranted: permission == LocationPermission.whileInUse || 
                         permission == LocationPermission.always,
    );
  }

  Future<void> determinePosition() async {
    state = state.copyWith(isLoading: true);

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      
      _locationStreamController.add(position);
      state = state.copyWith(position: position, isLoading: false);
      
      // Background geocoding
      final geocodingService = ref.read(geocodingServiceProvider);
      final code = await geocodingService.getCountryCode(position.latitude, position.longitude);
      if (code != null) {
        state = state.copyWith(countryCode: code);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().contains('Timeout') 
            ? 'GPS lock timed out. Please ensure you have a clear view of the sky.' 
            : e.toString(),
      );
    }
  }

  Future<void> requestPermission() async {
    final locationService = ref.read(locationServiceProvider);
    final permission = await locationService.requestPermission();
    _updatePermissionStatus(permission);
  }

  void _updatePermissionStatus(LocationPermission permission) async {
    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    
    state = state.copyWith(permissionGranted: granted);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_permission_granted', granted);
  }
}
