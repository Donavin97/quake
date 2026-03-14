import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/earthquake.dart';
import '../models/circle_member.dart';
import 'earthquake_provider.dart';
import 'location_provider.dart';
import 'circle_provider.dart';

part 'safety_provider.freezed.dart';
part 'safety_provider.g.dart';

@freezed
class SafetyState with _$SafetyState {
  const factory SafetyState({
    Earthquake? pendingSafetyCheck,
    @Default({}) Set<String> processedQuakes,
  }) = _SafetyState;
}

@riverpod
class Safety extends _$Safety {
  @override
  SafetyState build() {
    // Listen to earthquakeNotifierProvider for threats
    ref.listen(earthquakeNotifierProvider, (previous, next) {
      _checkForThreats(next);
    });

    return const SafetyState();
  }

  void _checkForThreats(EarthquakeState earthquakeState) {
    if (earthquakeState.allEarthquakes.isEmpty) return;

    final latestQuake = earthquakeState.allEarthquakes.first;
    
    if (state.processedQuakes.contains(latestQuake.id)) return;

    final locationState = ref.read(locationProvider);
    final userPos = locationState.position;
    if (userPos == null) return;

    final distance = Geolocator.distanceBetween(
      userPos.latitude,
      userPos.longitude,
      latestQuake.latitude,
      latestQuake.longitude,
    );

    final bool isThreat = (latestQuake.magnitude >= 5.0 && distance < 100000) || 
                   (latestQuake.magnitude >= 7.0 && distance < 300000);

    if (isThreat) {
      state = state.copyWith(
        pendingSafetyCheck: latestQuake,
        processedQuakes: {...state.processedQuakes, latestQuake.id},
      );
    }
  }

  void markSafe() {
    final pendingQuake = state.pendingSafetyCheck;
    if (pendingQuake == null) return;
    
    final locationState = ref.read(locationProvider);
    final circleState = ref.read(circleProvider);
    final circleNotifier = ref.read(circleProvider.notifier);
    
    final pos = locationState.position;
    for (final circle in circleState.circles) {
      circleNotifier.updateSafetyStatus(
        circle.id, 
        SafetyStatus.safe,
        earthquakeId: pendingQuake.id,
        lat: pos?.latitude,
        lon: pos?.longitude,
      );
    }
    _dismiss();
  }

  void markUnsafe() {
    final pendingQuake = state.pendingSafetyCheck;
    if (pendingQuake == null) return;
    
    final locationState = ref.read(locationProvider);
    final circleState = ref.read(circleProvider);
    final circleNotifier = ref.read(circleProvider.notifier);
    
    final pos = locationState.position;
    for (final circle in circleState.circles) {
      circleNotifier.updateSafetyStatus(
        circle.id, 
        SafetyStatus.unsafe,
        earthquakeId: pendingQuake.id,
        lat: pos?.latitude,
        lon: pos?.longitude,
      );
    }
    _dismiss();
  }

  void ignore() {
    _dismiss();
  }

  void _dismiss() {
    state = state.copyWith(pendingSafetyCheck: null);
  }
}
