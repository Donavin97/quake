import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repositories/earthquake_repository.dart';
import '../services/api_service.dart';
import '../services/geocoding_service.dart';
import '../services/websocket_service.dart';
import '../services/user_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../services/circle_service.dart';
import '../services/felt_report_service.dart';
import '../services/haptic_service.dart';
import '../services/waveform_service.dart';

part 'service_providers.g.dart';

@riverpod
LocationService locationService(LocationServiceRef ref) {
  return LocationService();
}

@riverpod
FirebaseAuth firebaseAuth(FirebaseAuthRef ref) {
  return FirebaseAuth.instance;
}

@riverpod
FirebaseFirestore firebaseFirestore(FirebaseFirestoreRef ref) {
  return FirebaseFirestore.instance;
}

@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}

@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return ref.watch(authServiceProvider).authStateChanges;
}

@riverpod
ApiService apiService(ApiServiceRef ref) {
  return ApiService();
}

@riverpod
GeocodingService geocodingService(GeocodingServiceRef ref) {
  return GeocodingService();
}

@riverpod
UserService userService(UserServiceRef ref) {
  return UserService();
}

@riverpod
WebSocketService webSocketService(WebSocketServiceRef ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
}

@riverpod
EarthquakeRepository earthquakeRepository(EarthquakeRepositoryRef ref) {
  return EarthquakeRepository(
    ref.watch(apiServiceProvider),
    ref.watch(geocodingServiceProvider),
  );
}

@riverpod
CircleService circleService(CircleServiceRef ref) {
  return CircleService();
}

@riverpod
FeltReportService feltReportService(FeltReportServiceRef ref) {
  return FeltReportService();
}

@riverpod
HapticService hapticService(HapticServiceRef ref) {
  return HapticService();
}

@riverpod
WaveformService waveformService(WaveformServiceRef ref) {
  return WaveformService();
}
