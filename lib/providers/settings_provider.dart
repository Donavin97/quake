import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/time_window.dart';
import '../services/background_service.dart';
import '../models/user_preferences.dart';
import '../models/notification_profile.dart';
import 'location_provider.dart';
import 'service_providers.dart';

part 'settings_provider.freezed.dart';
part 'settings_provider.g.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(false) bool isLoaded,
    @Default(UserPreferences()) UserPreferences userPreferences,
    NotificationProfile? activeNotificationProfile,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(TimeWindow.day) TimeWindow timeWindow,
    @Default('usgs') String earthquakeProvider,
    @Default({}) Set<String> subscribedTopics,
    @Default(true) bool showPlates,
    @Default(true) bool showFaults,
    @Default(true) bool showFeltRadius,
    @Default(1.0) double mapButtonScale,
    @Default(1.0) double smallMarkerScale,
    DateTime? lastSynced,
  }) = _SettingsState;
}

@riverpod
class Settings extends _$Settings {
  @override
  SettingsState build() {
    // Immediate build with default state
    _init();
    return const SettingsState();
  }

  void _init() {
    // Listen to auth changes - this is our primary trigger
    final auth = ref.read(firebaseAuthProvider);
    auth.userChanges().listen((user) {
      if (user != null) {
        // User logged in or already logged in
        _loadPreferences();
      } else {
        // User logged out
        _resetToDefaults();
      }
    });

    // Reactively update subscriptions when location changes
    ref.listen(locationProvider, (previous, next) {
      if (previous?.position != next.position) {
        _updateSubscriptions();
      }
    });
  }

  void _resetToDefaults() {
    state = state.copyWith(userPreferences: const UserPreferences(), isLoaded: true);
  }

  Future<void> _loadPreferences() async {
    try {
      final auth = ref.read(firebaseAuthProvider);
      final user = auth.currentUser;
      
      // 1. First, load from SharedPreferences for "Instant On" UI
      final prefs = await SharedPreferences.getInstance();
      
      UserPreferences? currentPrefs;
      final userPrefsJson = prefs.getString('userPreferences');
      if (userPrefsJson != null) {
        try {
          currentPrefs = UserPreferences.fromJson(jsonDecode(userPrefsJson));
        } catch (e) {
          debugPrint('Settings Parse Error: $e');
        }
      }
      
      currentPrefs ??= const UserPreferences();

      // Load app-wide specific keys
      final showPlates = prefs.getBool('showPlates') ?? true;
      final showFaults = prefs.getBool('showFaults') ?? true;
      final showFeltRadius = prefs.getBool('showFeltRadius') ?? true;
      final mapButtonScale = prefs.getDouble('mapButtonScale') ?? 1.0;
      final smallMarkerScale = prefs.getDouble('smallMarkerScale') ?? 1.0;

      // Update state immediately with local data
      state = state.copyWith(
        userPreferences: currentPrefs,
        activeNotificationProfile: currentPrefs.notificationProfiles.firstOrNull,
        themeMode: ThemeMode.values[currentPrefs.themeMode.clamp(0, 2)],
        timeWindow: currentPrefs.timeWindow,
        earthquakeProvider: currentPrefs.earthquakeProvider,
        subscribedTopics: Set<String>.from(currentPrefs.subscribedTopics),
        showPlates: showPlates,
        showFaults: showFaults,
        showFeltRadius: showFeltRadius,
        mapButtonScale: mapButtonScale,
        smallMarkerScale: smallMarkerScale,
        isLoaded: true,
      );

      // 2. Then, fetch from Firestore to sync (Background)
      if (user != null) {
        final userService = ref.read(userServiceProvider);
        final remotePrefs = await userService.getUserPreferences(user.uid);
        
        if (remotePrefs != null) {
          // Compare or merge (Simple override for now as Firestore is truth)
          state = state.copyWith(
            userPreferences: remotePrefs,
            activeNotificationProfile: remotePrefs.notificationProfiles.firstOrNull,
            themeMode: ThemeMode.values[remotePrefs.themeMode.clamp(0, 2)],
            timeWindow: remotePrefs.timeWindow,
            earthquakeProvider: remotePrefs.earthquakeProvider,
            subscribedTopics: Set<String>.from(remotePrefs.subscribedTopics),
            lastSynced: DateTime.now(),
          );
          
          // Sync back to local storage
          await _saveToLocalCache();
        }
      }

      await _updateSubscriptions();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> _saveToLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final locationState = ref.read(locationProvider);
    final position = locationState.position;
    
    await prefs.setString('userPreferences', jsonEncode(state.userPreferences.toJson()));
    await prefs.setDouble('minMagnitude', state.activeNotificationProfile?.minMagnitude ?? 0.0);
    await prefs.setBool('notificationsEnabled', state.userPreferences.notificationsEnabled);
    await prefs.setBool('communitySeismographEnabled', state.userPreferences.communitySeismographEnabled);
    await prefs.setDouble('radius', state.activeNotificationProfile?.radius ?? 0.0);
    // vibration settings are complex, just relying on userPreferences object for those in local cache primarily
    if (position != null) {
      await prefs.setDouble('lastLatitude', position.latitude);
      await prefs.setDouble('lastLongitude', position.longitude);
    }
    
    await prefs.setBool('showPlates', state.showPlates);
    await prefs.setBool('showFaults', state.showFaults);
    await prefs.setBool('showFeltRadius', state.showFeltRadius);
    await prefs.setDouble('mapButtonScale', state.mapButtonScale);
    await prefs.setDouble('smallMarkerScale', state.smallMarkerScale);
  }

  Future<void> _savePreferences() async {
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;
    if (user != null) {
      final userService = ref.read(userServiceProvider);
      final locationState = ref.read(locationProvider);
      final fcmToken = await FirebaseMessaging.instance.getToken();
      
      final updatedPrefs = state.userPreferences.copyWith(
        notificationsEnabled: state.userPreferences.notificationsEnabled,
        themeMode: state.themeMode.index,
        timeWindow: state.timeWindow,
        earthquakeProvider: state.earthquakeProvider,
        subscribedTopics: state.subscribedTopics.toList(),
        mapButtonScale: state.mapButtonScale,
        smallMarkerScale: state.smallMarkerScale,
      );

      await userService.saveUserPreferences(
        user.uid, 
        updatedPrefs,
        fcmToken: fcmToken, 
        position: locationState.position
      );
      await _saveToLocalCache();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _savePreferences();
  }

  Future<void> setTimeWindow(TimeWindow window) async {
    state = state.copyWith(timeWindow: window);
    await _savePreferences();
  }

  Future<void> setEarthquakeProvider(String provider) async {
    state = state.copyWith(earthquakeProvider: provider);
    await _savePreferences();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      final AuthorizationStatus status = await BackgroundService.requestPermission();
      if (status == AuthorizationStatus.denied) {
        state = state.copyWith(
          userPreferences: state.userPreferences.copyWith(notificationsEnabled: false)
        );
        await _savePreferences();
        return;
      }
      state = state.copyWith(
        userPreferences: state.userPreferences.copyWith(notificationsEnabled: true)
      );
      await _savePreferences();
      await _updateSubscriptions();
    } else {
      state = state.copyWith(
        userPreferences: state.userPreferences.copyWith(notificationsEnabled: false)
      );
      await _savePreferences();
      await _unsubscribeFromAllTopics();
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (e) {
        debugPrint('Error deleting FCM token: $e');
      }
    }
  }

  Future<void> setCommunitySeismographEnabled(bool enabled) async {
    state = state.copyWith(
      userPreferences: state.userPreferences.copyWith(communitySeismographEnabled: enabled)
    );
    await _savePreferences();

    // Store userId for background isolate access
    if (enabled) {
      final auth = ref.read(firebaseAuthProvider);
      final user = auth.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bg_user_id', user.uid);
      }
    }
  }

  Future<void> setShowPlates(bool show) async {
    state = state.copyWith(showPlates: show);
    await _saveToLocalCache();
  }

  Future<void> setShowFaults(bool show) async {
    state = state.copyWith(showFaults: show);
    await _saveToLocalCache();
  }

  Future<void> setShowFeltRadius(bool show) async {
    state = state.copyWith(showFeltRadius: show);
    await _saveToLocalCache();
  }

  Future<void> setMapButtonScale(double scale) async {
    state = state.copyWith(mapButtonScale: scale);
    await _savePreferences();
  }

  Future<void> setSmallMarkerScale(double scale) async {
    state = state.copyWith(smallMarkerScale: scale);
    await _savePreferences();
  }

  Future<void> setActiveNotificationProfile(NotificationProfile? profile) async {
    state = state.copyWith(activeNotificationProfile: profile);
  }

  Future<void> updateProfile(NotificationProfile profile) async {
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;
    if (user == null) return;
    
    final userService = ref.read(userServiceProvider);
    await userService.updateNotificationProfile(user.uid, profile);
    await _loadPreferences();
  }

  Future<void> addProfile(NotificationProfile profile) async {
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;
    if (user == null) return;
    
    final userService = ref.read(userServiceProvider);
    await userService.addNotificationProfile(user.uid, profile);
    await _loadPreferences();
  }

  Future<void> deleteProfile(String profileId) async {
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;
    if (user == null) return;
    
    final userService = ref.read(userServiceProvider);
    await userService.deleteNotificationProfile(user.uid, profileId);
    await _loadPreferences();
  }

  Future<void> _updateSubscriptions() async {
    if (!state.userPreferences.notificationsEnabled) return;

    final newTopics = <String>{'global'};
    
    int globalMinMagnitude = 9;
    if (state.userPreferences.notificationProfiles.isNotEmpty) {
      for(final profile in state.userPreferences.notificationProfiles) {
        if (profile.minMagnitude < globalMinMagnitude) {
          globalMinMagnitude = profile.minMagnitude.toInt();
        }
      }
    } else {
      globalMinMagnitude = 0;
    }

    for (int i = globalMinMagnitude; i <= 9; i++) {
      newTopics.add('minmag_$i');
    }

    final locationState = ref.read(locationProvider);
    final currentPosition = locationState.position;
    if (currentPosition != null) {
      final geohash = GeoHasher().encode(currentPosition.longitude, currentPosition.latitude);
      newTopics.add('geo_${geohash.substring(0, 1)}');
      newTopics.add('geo_${geohash.substring(0, 2)}');
    }

    for (final profile in state.userPreferences.notificationProfiles) {
      final geohash = GeoHasher().encode(profile.longitude, profile.latitude);
      newTopics.add('geo_${geohash.substring(0, 1)}');
      newTopics.add('geo_${geohash.substring(0, 2)}');
    }

    final currentSubscribed = state.subscribedTopics;
    final toAdd = newTopics.difference(currentSubscribed);
    final toRemove = currentSubscribed.difference(newTopics);

    for (final topic in toAdd) {
      try {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      } catch (e) {
        debugPrint('Error subscribing to topic $topic: $e');
      }
    }

    for (final topic in toRemove) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      } catch (e) {
        debugPrint('Error unsubscribing from topic $topic: $e');
      }
    }

    state = state.copyWith(subscribedTopics: newTopics);
    await _savePreferences();
  }

  Future<void> _unsubscribeFromAllTopics() async {
    for (final topic in state.subscribedTopics) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    }
    state = state.copyWith(subscribedTopics: {});
    await _savePreferences();
  }

  Future<void> setSuccessVibration(VibrationSettings settings) async {
    state = state.copyWith(
      userPreferences: state.userPreferences.copyWith(successVibration: settings)
    );
    await _savePreferences();
  }

  Future<void> setErrorVibration(VibrationSettings settings) async {
    state = state.copyWith(
      userPreferences: state.userPreferences.copyWith(errorVibration: settings)
    );
    await _savePreferences();
  }

  // Vibration test methods
  Future<void> testSuccessVibration([VibrationSettings? temporarySettings]) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) return;
      
      final settings = temporarySettings ?? state.userPreferences.successVibration;
      final duration = settings.getDurationForIntensity(VibrationIntensity.medium);
      await Vibration.vibrate(duration: duration);
    } catch (_) {}
  }

  Future<void> testErrorVibration([VibrationSettings? temporarySettings]) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) return;
      
      final settings = temporarySettings ?? state.userPreferences.errorVibration;
      final duration = settings.getDurationForIntensity(VibrationIntensity.heavy);
      if (settings.pattern > 1) {
        final pattern = <int>[0];
        for (int i = 0; i < settings.pattern; i++) {
          pattern.add(duration);
          if (i < settings.pattern - 1) {
            pattern.add(100);
          }
        }
        await Vibration.vibrate(pattern: pattern);
      } else {
        await Vibration.vibrate(duration: duration);
      }
    } catch (_) {}
  }
}
