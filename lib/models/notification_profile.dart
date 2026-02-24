import 'package:hive/hive.dart';

part 'notification_profile.g.dart';

@HiveType(typeId: 3) // Assign a unique typeId
class NotificationProfile extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  double latitude;
  @HiveField(3)
  double longitude;
  @HiveField(4)
  double radius; // in km
  @HiveField(5)
  double minMagnitude;
  @HiveField(6)
  bool quietHoursEnabled;
  @HiveField(7)
  List<int> quietHoursStart; // [hour, minute]
  @HiveField(8)
  List<int> quietHoursEnd; // [hour, minute]
  @HiveField(9)
  List<int> quietHoursDays; // [0-6 for Sun-Sat]
  @HiveField(10)
  bool alwaysNotifyRadiusEnabled;
  @HiveField(11)
  double alwaysNotifyRadiusValue;
  @HiveField(12)
  double emergencyMagnitudeThreshold;
  @HiveField(13)
  double emergencyRadius;
  @HiveField(14)
  double globalMinMagnitudeOverrideQuietHours; // New field

  NotificationProfile({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.minMagnitude,
    this.quietHoursEnabled = false,
    this.quietHoursStart = const [22, 0],
    this.quietHoursEnd = const [6, 0],
    this.quietHoursDays = const [0, 1, 2, 3, 4, 5, 6],
    this.alwaysNotifyRadiusEnabled = false,
    this.alwaysNotifyRadiusValue = 0.0,
    this.emergencyMagnitudeThreshold = 0.0,
    this.emergencyRadius = 0.0,
    this.globalMinMagnitudeOverrideQuietHours = 0.0, // Initialize new field
  });

  factory NotificationProfile.fromJson(Map<String, dynamic> json) {
    return NotificationProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      minMagnitude: (json['minMagnitude'] as num).toDouble(),
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: (json['quietHoursStart'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [22, 0],
      quietHoursEnd: (json['quietHoursEnd'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [6, 0],
      quietHoursDays: (json['quietHoursDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [0, 1, 2, 3, 4, 5, 6],
      alwaysNotifyRadiusEnabled: json['alwaysNotifyRadiusEnabled'] as bool? ?? false,
      alwaysNotifyRadiusValue: (json['alwaysNotifyRadiusValue'] as num?)?.toDouble() ?? 0.0,
      emergencyMagnitudeThreshold: (json['emergencyMagnitudeThreshold'] as num?)?.toDouble() ?? 0.0,
      emergencyRadius: (json['emergencyRadius'] as num?)?.toDouble() ?? 0.0,
      globalMinMagnitudeOverrideQuietHours: (json['globalMinMagnitudeOverrideQuietHours'] as num?)?.toDouble() ?? 0.0, // Parse new field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'minMagnitude': minMagnitude,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'quietHoursDays': quietHoursDays,
      'alwaysNotifyRadiusEnabled': alwaysNotifyRadiusEnabled,
      'alwaysNotifyRadiusValue': alwaysNotifyRadiusValue,
      'emergencyMagnitudeThreshold': emergencyMagnitudeThreshold,
      'emergencyRadius': emergencyRadius,
      'globalMinMagnitudeOverrideQuietHours': globalMinMagnitudeOverrideQuietHours, // Serialize new field
    };
  }



  // Deep copy constructor for immutability when using ChangeNotifier
  NotificationProfile copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radius,
    double? minMagnitude,
    bool? quietHoursEnabled,
    List<int>? quietHoursStart,
    List<int>? quietHoursEnd,
    List<int>? quietHoursDays,
    bool? alwaysNotifyRadiusEnabled,
    double? alwaysNotifyRadiusValue,
    double? emergencyMagnitudeThreshold,
    double? emergencyRadius,
    double? globalMinMagnitudeOverrideQuietHours, // Add to copyWith
  }) {
    return NotificationProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      minMagnitude: minMagnitude ?? this.minMagnitude,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? [...this.quietHoursStart], // Deep copy list
      quietHoursEnd: quietHoursEnd ?? [...this.quietHoursEnd], // Deep copy list
      quietHoursDays: quietHoursDays ?? [...this.quietHoursDays], // Deep copy list
      alwaysNotifyRadiusEnabled: alwaysNotifyRadiusEnabled ?? this.alwaysNotifyRadiusEnabled,
      alwaysNotifyRadiusValue: alwaysNotifyRadiusValue ?? this.alwaysNotifyRadiusValue,
      emergencyMagnitudeThreshold: emergencyMagnitudeThreshold ?? this.emergencyMagnitudeThreshold,
      emergencyRadius: emergencyRadius ?? this.emergencyRadius,
      globalMinMagnitudeOverrideQuietHours: globalMinMagnitudeOverrideQuietHours ?? this.globalMinMagnitudeOverrideQuietHours, // Assign new field
    );
  }
}
