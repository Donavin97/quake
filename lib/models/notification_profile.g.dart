// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationProfileImpl _$$NotificationProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationProfileImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      minMagnitude: (json['minMagnitude'] as num).toDouble(),
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: (json['quietHoursStart'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [22, 0],
      quietHoursEnd: (json['quietHoursEnd'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [6, 0],
      quietHoursDays: (json['quietHoursDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [0, 1, 2, 3, 4, 5, 6],
      alwaysNotifyRadiusEnabled:
          json['alwaysNotifyRadiusEnabled'] as bool? ?? false,
      alwaysNotifyRadiusValue:
          (json['alwaysNotifyRadiusValue'] as num?)?.toDouble() ?? 0.0,
      emergencyMagnitudeThreshold:
          (json['emergencyMagnitudeThreshold'] as num?)?.toDouble() ?? 0.0,
      emergencyRadius: (json['emergencyRadius'] as num?)?.toDouble() ?? 0.0,
      globalMinMagnitudeOverrideQuietHours:
          (json['globalMinMagnitudeOverrideQuietHours'] as num?)?.toDouble() ??
              0.0,
      timezone: json['timezone'] as String?,
    );

Map<String, dynamic> _$$NotificationProfileImplToJson(
        _$NotificationProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius': instance.radius,
      'minMagnitude': instance.minMagnitude,
      'quietHoursEnabled': instance.quietHoursEnabled,
      'quietHoursStart': instance.quietHoursStart,
      'quietHoursEnd': instance.quietHoursEnd,
      'quietHoursDays': instance.quietHoursDays,
      'alwaysNotifyRadiusEnabled': instance.alwaysNotifyRadiusEnabled,
      'alwaysNotifyRadiusValue': instance.alwaysNotifyRadiusValue,
      'emergencyMagnitudeThreshold': instance.emergencyMagnitudeThreshold,
      'emergencyRadius': instance.emergencyRadius,
      'globalMinMagnitudeOverrideQuietHours':
          instance.globalMinMagnitudeOverrideQuietHours,
      'timezone': instance.timezone,
    };
