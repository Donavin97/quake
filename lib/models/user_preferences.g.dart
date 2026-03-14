// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VibrationSettingsImpl _$$VibrationSettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$VibrationSettingsImpl(
      duration: (json['duration'] as num?)?.toInt() ?? 50,
      pattern: (json['pattern'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$VibrationSettingsImplToJson(
        _$VibrationSettingsImpl instance) =>
    <String, dynamic>{
      'duration': instance.duration,
      'pattern': instance.pattern,
    };

_$UserPreferencesImpl _$$UserPreferencesImplFromJson(
        Map<String, dynamic> json) =>
    _$UserPreferencesImpl(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      communitySeismographEnabled:
          json['communitySeismographEnabled'] as bool? ?? false,
      notificationProfiles: (json['notificationProfiles'] as List<dynamic>?)
              ?.map((e) =>
                  NotificationProfile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      themeMode: (json['themeMode'] as num?)?.toInt() ?? 0,
      timeWindow:
          $enumDecodeNullable(_$TimeWindowEnumMap, json['timeWindow']) ??
              TimeWindow.day,
      earthquakeProvider: json['earthquakeProvider'] as String? ?? 'usgs',
      subscribedTopics: (json['subscribedTopics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      successVibration: json['successVibration'] == null
          ? const VibrationSettings()
          : VibrationSettings.fromJson(
              json['successVibration'] as Map<String, dynamic>),
      errorVibration: json['errorVibration'] == null
          ? const VibrationSettings(duration: 100, pattern: 3)
          : VibrationSettings.fromJson(
              json['errorVibration'] as Map<String, dynamic>),
      mapButtonScale: (json['mapButtonScale'] as num?)?.toDouble() ?? 1.0,
      smallMarkerScale: (json['smallMarkerScale'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$$UserPreferencesImplToJson(
        _$UserPreferencesImpl instance) =>
    <String, dynamic>{
      'notificationsEnabled': instance.notificationsEnabled,
      'communitySeismographEnabled': instance.communitySeismographEnabled,
      'notificationProfiles': instance.notificationProfiles,
      'themeMode': instance.themeMode,
      'timeWindow': _$TimeWindowEnumMap[instance.timeWindow]!,
      'earthquakeProvider': instance.earthquakeProvider,
      'subscribedTopics': instance.subscribedTopics,
      'successVibration': instance.successVibration,
      'errorVibration': instance.errorVibration,
      'mapButtonScale': instance.mapButtonScale,
      'smallMarkerScale': instance.smallMarkerScale,
    };

const _$TimeWindowEnumMap = {
  TimeWindow.day: 'day',
  TimeWindow.week: 'week',
  TimeWindow.month: 'month',
};
