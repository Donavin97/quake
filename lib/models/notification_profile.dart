import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_profile.freezed.dart';
part 'notification_profile.g.dart';

@freezed
class NotificationProfile with _$NotificationProfile {
  const factory NotificationProfile({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    required double minMagnitude,
    @Default(false) bool quietHoursEnabled,
    @Default([22, 0]) List<int> quietHoursStart,
    @Default([6, 0]) List<int> quietHoursEnd,
    @Default([0, 1, 2, 3, 4, 5, 6]) List<int> quietHoursDays,
    @Default(false) bool alwaysNotifyRadiusEnabled,
    @Default(0.0) double alwaysNotifyRadiusValue,
    @Default(0.0) double emergencyMagnitudeThreshold,
    @Default(0.0) double emergencyRadius,
    @Default(0.0) double globalMinMagnitudeOverrideQuietHours,
    String? timezone,
  }) = _NotificationProfile;

  factory NotificationProfile.fromJson(Map<String, dynamic> json) =>
      _$NotificationProfileFromJson(json);
}
