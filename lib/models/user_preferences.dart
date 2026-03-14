import 'package:freezed_annotation/freezed_annotation.dart';
import 'notification_profile.dart';
import 'time_window.dart';

part 'user_preferences.freezed.dart';
part 'user_preferences.g.dart';

@freezed
class VibrationSettings with _$VibrationSettings {
  const factory VibrationSettings({
    @Default(50) int duration,
    @Default(1) int pattern,
  }) = _VibrationSettings;

  factory VibrationSettings.fromJson(Map<String, dynamic> json) =>
      _$VibrationSettingsFromJson(json);
}

extension VibrationSettingsX on VibrationSettings {
  int getDurationForIntensity(VibrationIntensity intensity) {
    final baseDuration = duration;
    switch (intensity) {
      case VibrationIntensity.light:
        return (baseDuration * 0.5).toInt().clamp(10, 200);
      case VibrationIntensity.medium:
        return baseDuration;
      case VibrationIntensity.heavy:
        return (baseDuration * pattern).clamp(10, 500);
    }
  }
}

enum VibrationIntensity { light, medium, heavy }

@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    @Default(true) bool notificationsEnabled,
    @Default(false) bool communitySeismographEnabled,
    @Default([]) List<NotificationProfile> notificationProfiles,
    @Default(0) int themeMode,
    @Default(TimeWindow.day) TimeWindow timeWindow,
    @Default('usgs') String earthquakeProvider,
    @Default([]) List<String> subscribedTopics,
    @Default(VibrationSettings()) VibrationSettings successVibration,
    @Default(VibrationSettings(duration: 100, pattern: 3)) VibrationSettings errorVibration,
    @Default(1.0) double mapButtonScale,
    @Default(1.0) double smallMarkerScale,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
}
