import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:hive/hive.dart';

import '../models/time_window.dart';
import '../services/background_service.dart';
import '../services/user_service.dart';
import '../models/user_preferences.dart'; // Import UserPreferences
import '../models/notification_profile.dart'; // Import NotificationProfile
import 'location_provider.dart';

class SettingsProvider with ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _userService = UserService();
  final LocationProvider _locationProvider;

  UserPreferences _userPreferences = UserPreferences(); // Store the full user preferences
  NotificationProfile? _activeNotificationProfile; // The profile currently being viewed/edited

  // App-wide settings not tied to a specific notification profile
  var _themeMode = ThemeMode.system;
  var _timeWindow = TimeWindow.day;
  var _earthquakeProvider = 'usgs';
  var _subscribedTopics = <String>{};

  // Getters for main settings (delegated to _userPreferences or _activeNotificationProfile)
  ThemeMode get themeMode => _themeMode; // This remains for app-wide theme
  TimeWindow get timeWindow => _timeWindow; // This remains for app-wide list filtering
  String get earthquakeProvider => _earthquakeProvider; // This remains for app-wide list filtering

  // Access the list of all notification profiles
  List<NotificationProfile> get notificationProfiles => _userPreferences.notificationProfiles;

  // Access settings from the active profile
  int get minMagnitude => _activeNotificationProfile?.minMagnitude.toInt() ?? 0;
  bool get notificationsEnabled => _userPreferences.notificationsEnabled; // This remains for global enable/disable
  double get radius => _activeNotificationProfile?.radius ?? 0.0;
  double get listRadius => (_activeNotificationProfile?.radius ?? 0.0); // Use active profile's radius for list display
  bool get quietHoursEnabled => _activeNotificationProfile?.quietHoursEnabled ?? false;
  List<int> get quietHoursStart => _activeNotificationProfile?.quietHoursStart ?? const [22, 0];
  List<int> get quietHoursEnd => _activeNotificationProfile?.quietHoursEnd ?? const [6, 0];
  List<int> get quietHoursDays => _activeNotificationProfile?.quietHoursDays ?? const [0, 1, 2, 3, 4, 5, 6];
  double get emergencyMagnitudeThreshold => _activeNotificationProfile?.emergencyMagnitudeThreshold ?? 0.0;
  double get emergencyRadius => _activeNotificationProfile?.emergencyRadius ?? 0.0;
  double get globalMinMagnitudeOverrideQuietHours => _activeNotificationProfile?.globalMinMagnitudeOverrideQuietHours ?? 0.0;
  bool get alwaysNotifyRadiusEnabled => _activeNotificationProfile?.alwaysNotifyRadiusEnabled ?? false;
  double get alwaysNotifyRadiusValue => _activeNotificationProfile?.alwaysNotifyRadiusValue ?? 0.0;

  SettingsProvider(this._locationProvider) {
    _loadPreferences();
    _auth.userChanges().listen((user) {
      if (user != null) {
        _loadPreferences();
      }
    });
    _locationProvider.locationStream.listen((_) {
      _updateSubscriptions();
    });
  }

  Future<void> _loadPreferences() async {
    final user = _auth.currentUser;
    if (user != null) {
      _userPreferences = (await _userService.getUserPreferences(user.uid)) ?? UserPreferences();
      
      // If there are no profiles (e.g., new user or old data without profiles), create a default one
      if (_userPreferences.notificationProfiles.isEmpty) {
          final currentPosition = _locationProvider.currentPosition;
          _userPreferences = _userPreferences.copyWith(
            notificationProfiles: [
              NotificationProfile(
                id: 'default',
                name: 'Default Profile',
                latitude: currentPosition?.latitude ?? 0.0,
                longitude: currentPosition?.longitude ?? 0.0,
                radius: 0.0, // Default to worldwide
                minMagnitude: 4.5,
                quietHoursEnabled: false,
                quietHoursStart: const [22, 0],
                quietHoursEnd: const [6, 0],
                quietHoursDays: const [0, 1, 2, 3, 4, 5, 6],
                emergencyMagnitudeThreshold: 5.0,
                emergencyRadius: 100.0,
                globalMinMagnitudeOverrideQuietHours: 0.0,
                alwaysNotifyRadiusEnabled: false,
                alwaysNotifyRadiusValue: 0.0,
              )
            ]
          );
      }
      _activeNotificationProfile = _userPreferences.notificationProfiles.first; // Set the first profile as active
      
      // Load app-wide settings from the loaded UserPreferences object
      _themeMode = ThemeMode.values[_userPreferences.themeMode];
      _timeWindow = _userPreferences.timeWindow;
      _earthquakeProvider = _userPreferences.earthquakeProvider;
      _subscribedTopics = Set<String>.from(_userPreferences.subscribedTopics);

    } else {
      _userPreferences = UserPreferences(); // Reset to default if no user
      _activeNotificationProfile = null;
    }
    await _updateSubscriptions();
    await _saveToLocalCache();
    notifyListeners();
  }

  Future<void> _saveToLocalCache() async {
    final box = await Hive.openBox('app_settings');
    final position = _locationProvider.currentPosition;
    await box.putAll({
      'minMagnitude': _activeNotificationProfile?.minMagnitude.toInt() ?? 0,
      'notificationsEnabled': _userPreferences.notificationsEnabled,
      'radius': _activeNotificationProfile?.radius ?? 0.0,
      'listRadius': _activeNotificationProfile?.radius ?? 0.0, // Use active profile's radius for list display
      'quietHoursEnabled': _activeNotificationProfile?.quietHoursEnabled ?? false,
      'quietHoursStart': _activeNotificationProfile?.quietHoursStart,
      'quietHoursEnd': _activeNotificationProfile?.quietHoursEnd,
      'quietHoursDays': _activeNotificationProfile?.quietHoursDays,
      'emergencyMagnitudeThreshold': _activeNotificationProfile?.emergencyMagnitudeThreshold ?? 0.0,
      'emergencyRadius': _activeNotificationProfile?.emergencyRadius ?? 0.0,
      'globalMinMagnitudeOverrideQuietHours': _activeNotificationProfile?.globalMinMagnitudeOverrideQuietHours ?? 0.0,
      'alwaysNotifyRadiusEnabled': _activeNotificationProfile?.alwaysNotifyRadiusEnabled ?? false,
      'alwaysNotifyRadiusValue': _activeNotificationProfile?.alwaysNotifyRadiusValue ?? 0.0,
      'lastLatitude': position?.latitude,
      'lastLongitude': position?.longitude,
      'notificationProfiles': _userPreferences.notificationProfiles, // Save full list
    });
  }

  Future<void> _savePreferences() async {
    final user = _auth.currentUser;
    if (user != null) {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final position = _locationProvider.currentPosition;
      
      // Update app-wide preferences within the _userPreferences object
      _userPreferences = _userPreferences.copyWith(
        notificationsEnabled: _userPreferences.notificationsEnabled,
        themeMode: _themeMode.index,
        timeWindow: _timeWindow,
        earthquakeProvider: _earthquakeProvider,
        subscribedTopics: _subscribedTopics.toList(),
      );

      await _userService.saveUserPreferences(
        user.uid, 
        _userPreferences, // Pass the entire UserPreferences object
        fcmToken: fcmToken, 
        position: position
      );
      await _saveToLocalCache();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setTimeWindow(TimeWindow window) async {
    _timeWindow = window;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setMinMagnitude(int magnitude) async {
    if (_activeNotificationProfile == null) return;
    _activeNotificationProfile = _activeNotificationProfile!.copyWith(minMagnitude: magnitude.toDouble());
    // Find and update the profile in the userPreferences list
    _userPreferences = _userPreferences.copyWith(
      notificationProfiles: _userPreferences.notificationProfiles.map((p) => 
        p.id == _activeNotificationProfile!.id ? _activeNotificationProfile! : p
      ).toList(),
    );
    await _savePreferences();
    await _updateSubscriptions();
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    // Only proceed if enabling notifications
    if (enabled) {
      final AuthorizationStatus status = await BackgroundService.requestPermission();
      if (status == AuthorizationStatus.denied) {
        // User denied permissions permanently, update internal state to reflect this
        _userPreferences = _userPreferences.copyWith(notificationsEnabled: false);
        await _savePreferences(); // Save the new 'false' status
        notifyListeners();
        // Potentially show a dialog to the user guiding them to settings
        return;
      }
      // If authorized or provisional, proceed
      _userPreferences = _userPreferences.copyWith(notificationsEnabled: enabled); // Re-set, in case it was provisional or authorized
      await _savePreferences();
      await _updateSubscriptions();
    } else {
      // If disabling notifications
      _userPreferences = _userPreferences.copyWith(notificationsEnabled: enabled);
      await _savePreferences();
      await _unsubscribeFromAllTopics();
    }
    notifyListeners();
  }

  Future<void> setRadius(double radius) async {
    if (_activeNotificationProfile == null) return;
    _activeNotificationProfile = _activeNotificationProfile!.copyWith(radius: radius);
    _userPreferences = _userPreferences.copyWith(
      notificationProfiles: _userPreferences.notificationProfiles.map((p) => 
        p.id == _activeNotificationProfile!.id ? _activeNotificationProfile! : p
      ).toList(),
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setListRadius(double radius) async {
    // This setter might become obsolete or needs to update a specific profile's radius
    // For now, it will update the active profile's radius
    if (_activeNotificationProfile == null) return;
    _activeNotificationProfile = _activeNotificationProfile!.copyWith(radius: radius);
    _userPreferences = _userPreferences.copyWith(
      notificationProfiles: _userPreferences.notificationProfiles.map((p) => 
        p.id == _activeNotificationProfile!.id ? _activeNotificationProfile! : p
      ).toList(),
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setEarthquakeProvider(String provider) async {
    _earthquakeProvider = provider;
    await _savePreferences();
    notifyListeners();
  }

  // New setters for quiet hours and emergency override
  Future<void> setQuietHoursEnabled(bool enabled) async {
    if (_activeNotificationProfile == null) return;
    _activeNotificationProfile = _activeNotificationProfile!.copyWith(quietHoursEnabled: enabled);
    _userPreferences = _userPreferences.copyWith(
      notificationProfiles: _userPreferences.notificationProfiles.map((p) => 
        p.id == _activeNotificationProfile!.id ? _activeNotificationProfile! : p
      ).toList(),
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setQuietHoursStart(List<int> time) async {
    if (_activeNotificationProfile == null) return;
    _activeNotificationProfile = _activeNotificationProfile!.copyWith(quietHoursStart: time);
    _userPreferences = _userPreferences.copyWith(
      notificationProfiles: _userPreferences.notificationProfiles.map((p) => 
        p.id == _activeNotificationProfile!.id ? _activeNotificationProfile! : p
      ).toList(),
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setQuietHoursEnd(List<int> time) async {
    if (_activeNotificationProfile == null) return;
    _activeNotificationProfile = _activeNotificationProfile!.copyWith(quietHoursEnd: time);
    _userPreferences = _userPreferences.copyWith(
      notificationProfiles: _userPreferences.notificationProfiles.map((p) => 
        p.id == _activeNotificationProfile!.id ? _activeNotificationProfile! : p
      ).toList(),
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setQuietHoursDays(List<int> days) async {
    if (_activeNotificationProfile == null) return;
    _activeNotificationProfile = _activeNotificationProfile!.copyWith(quietHoursDays: days);
    _userPreferences = _userPreferences.copyWith(
      notificationProfiles: _userPreferences.notificationProfiles.map((p) => 
        p.id == _activeNotificationProfile!.id ? _activeNotificationProfile! : p
      ).toList(),
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setEmergencyMagnitudeThreshold(double magnitude) async {
    if (_activeNotificationProfile == null) return;
    _activeNotificationProfile = _activeNotificationProfile!.copyWith(emergencyMagnitudeThreshold: magnitude);
    _userPreferences = _userPreferences.copyWith(
      notificationProfiles: _userPreferences.notificationProfiles.map((p) => 
        p.id == _activeNotificationProfile!.id ? _activeNotificationProfile! : p
      ).toList(),
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setEmergencyRadius(double radius) async {
    if (_activeNotificationProfile == null) return;
    _activeNotificationProfile = _activeNotificationProfile!.copyWith(emergencyRadius: radius);
    _userPreferences = _userPreferences.copyWith(
      notificationProfiles: _userPreferences.notificationProfiles.map((p) => 
        p.id == _activeNotificationProfile!.id ? _activeNotificationProfile! : p
      ).toList(),
    );
    await _savePreferences();
    notifyListeners();
  }

  // New setters for override fields
  Future<void> setGlobalMinMagnitudeOverrideQuietHours(double magnitude) async {
    if (_activeNotificationProfile == null) return;
    _activeNotificationProfile = _activeNotificationProfile!.copyWith(globalMinMagnitudeOverrideQuietHours: magnitude);
    _userPreferences = _userPreferences.copyWith(
      notificationProfiles: _userPreferences.notificationProfiles.map((p) => 
        p.id == _activeNotificationProfile!.id ? _activeNotificationProfile! : p
      ).toList(),
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setAlwaysNotifyRadiusEnabled(bool enabled) async {
    if (_activeNotificationProfile == null) return;
    _activeNotificationProfile = _activeNotificationProfile!.copyWith(alwaysNotifyRadiusEnabled: enabled);
    _userPreferences = _userPreferences.copyWith(
      notificationProfiles: _userPreferences.notificationProfiles.map((p) => 
        p.id == _activeNotificationProfile!.id ? _activeNotificationProfile! : p
      ).toList(),
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setAlwaysNotifyRadiusValue(double value) async {
    if (_activeNotificationProfile == null) return;
    _activeNotificationProfile = _activeNotificationProfile!.copyWith(alwaysNotifyRadiusValue: value);
    _userPreferences = _userPreferences.copyWith(
      notificationProfiles: _userPreferences.notificationProfiles.map((p) => 
        p.id == _activeNotificationProfile!.id ? _activeNotificationProfile! : p
      ).toList(),
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> _updateSubscriptions() async {
    if (!_userPreferences.notificationsEnabled) return;

    final newTopics = <String>{'global'};
    
    // Determine global minMagnitude by finding the lowest minMagnitude across all profiles
    int globalMinMagnitude = 9; // Start with highest possible magnitude
    if (_userPreferences.notificationProfiles.isNotEmpty) {
      for(final profile in _userPreferences.notificationProfiles) {
        if (profile.minMagnitude < globalMinMagnitude) {
          globalMinMagnitude = profile.minMagnitude.toInt();
        }
      }
    } else {
      // Fallback if somehow no profiles, use a default value (e.g., 0 for all)
      globalMinMagnitude = 0;
    }


    // Subscribe to all magnitude levels from our determined global minimum up to 9.
    for (int i = globalMinMagnitude; i <= 9; i++) {
      newTopics.add('minmag_$i');
    }

    // 1. Current Position Geohash
    final currentPosition = _locationProvider.currentPosition;
    if (currentPosition != null) {
      final geohash = GeoHasher().encode(currentPosition.longitude, currentPosition.latitude);
      newTopics.add('geo_${geohash.substring(0, 1)}');
      newTopics.add('geo_${geohash.substring(0, 2)}');
    }

    // 2. Geohashes for ALL Notification Profiles
    for (final profile in _userPreferences.notificationProfiles) {
      final geohash = GeoHasher().encode(profile.longitude, profile.latitude);
      // Use 1 and 2 character prefixes for broad and local geohash topics
      newTopics.add('geo_${geohash.substring(0, 1)}');
      newTopics.add('geo_${geohash.substring(0, 2)}');
    }

    final toAdd = newTopics.difference(_subscribedTopics);
    final toRemove = _subscribedTopics.difference(newTopics);

    for (final topic in toAdd) {
      try {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
        _subscribedTopics.add(topic);
      } catch (e) {
        debugPrint('Error subscribing to topic $topic: $e');
      }
    }

    for (final topic in toRemove) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        _subscribedTopics.remove(topic);
      } catch (e) {
        debugPrint('Error unsubscribing from topic $topic: $e');
      }
    }

    await _savePreferences();
  }

  Future<void> _unsubscribeFromAllTopics() async {
    for (final topic in _subscribedTopics) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    }
    _subscribedTopics.clear();
    await _savePreferences();
  }

  // Method to set the active notification profile for editing
  void setActiveNotificationProfile(NotificationProfile? profile) {
    _activeNotificationProfile = profile;
    notifyListeners();
  }

  // Method to add a new profile (delegates to UserService)
  Future<void> addProfile(NotificationProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _userService.addNotificationProfile(user.uid, profile);
    await _loadPreferences(); // Reload all preferences
  }

  // Method to update an existing profile (delegates to UserService)
  Future<void> updateProfile(NotificationProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _userService.updateNotificationProfile(user.uid, profile);
    await _loadPreferences(); // Reload all preferences
  }

  // Method to delete a profile (delegates to UserService)
  Future<void> deleteProfile(String profileId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _userService.deleteNotificationProfile(user.uid, profileId);
    await _loadPreferences(); // Reload all preferences
  }
}
