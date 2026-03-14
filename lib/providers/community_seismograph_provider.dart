import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/seismograph_background_service.dart';
import 'settings_provider.dart';

part 'community_seismograph_provider.freezed.dart';
part 'community_seismograph_provider.g.dart';

@freezed
class CommunitySeismographState with _$CommunitySeismographState {
  const factory CommunitySeismographState({
    @Default(false) bool isRecording,
    @Default(false) bool isEnabled,
    @Default(false) bool isSettling,
    DateTime? lastHeartbeat,
  }) = _CommunitySeismographState;
}

@riverpod
class CommunitySeismograph extends _$CommunitySeismograph {
  StreamSubscription? _serviceSubscription;

  @override
  CommunitySeismographState build() {
    final isEnabledInSettings = ref.watch(settingsProvider.select((s) => s.userPreferences.communitySeismographEnabled));
    
    // Establishing listener once
    _listenToService();

    // Side effect: Start/Stop service when setting changes
    ref.listen(settingsProvider.select((s) => s.userPreferences.communitySeismographEnabled), (previous, next) {
      if (next) {
        SeismographBackgroundService.start();
      } else {
        SeismographBackgroundService.stop();
      }
    });

    // Initial check
    if (isEnabledInSettings) {
      Future.microtask(() => SeismographBackgroundService.start());
    }

    ref.onDispose(() {
      _serviceSubscription?.cancel();
    });

    return CommunitySeismographState(isEnabled: isEnabledInSettings);
  }

  void _listenToService() {
    _serviceSubscription?.cancel();
    _serviceSubscription = FlutterBackgroundService().on('update').listen((event) {
      if (event != null) {
        state = state.copyWith(
          isRecording: event['isRecording'] ?? false,
          isSettling: event['isSettling'] ?? false,
          lastHeartbeat: event['lastHeartbeat'] != null 
              ? DateTime.tryParse(event['lastHeartbeat']) 
              : null,
        );
      }
    });
  }
}
