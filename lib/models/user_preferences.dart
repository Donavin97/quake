class UserPreferences {
  final double minMagnitude;
  final bool notificationsEnabled;
  final double radius;
  final bool quietHoursEnabled;
  final List<int> quietHoursStart; // [hour, minute]
  final List<int> quietHoursEnd;   // [hour, minute]
  final List<int> quietHoursDays;  // [0-6] for Sunday-Saturday
  final double emergencyMagnitudeThreshold;
  final double emergencyRadius; // in kilometers

  UserPreferences({
    this.minMagnitude = 4.5,
    this.notificationsEnabled = true,
    this.radius = 0,
    this.quietHoursEnabled = false,
    this.quietHoursStart = const [22, 0], // Default 10 PM
    this.quietHoursEnd = const [6, 0],   // Default 6 AM
    this.quietHoursDays = const [0, 1, 2, 3, 4, 5, 6], // Default all days
    this.emergencyMagnitudeThreshold = 5.0,
    this.emergencyRadius = 100.0,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> data) {
    return UserPreferences(
      minMagnitude: (data['minMagnitude'] as num?)?.toDouble() ?? 4.5,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      radius: (data['radius'] as num?)?.toDouble() ?? 0,
      quietHoursEnabled: data['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: (data['quietHoursStart'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [22, 0],
      quietHoursEnd: (data['quietHoursEnd'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [6, 0],
      quietHoursDays: (data['quietHoursDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [0, 1, 2, 3, 4, 5, 6],
      emergencyMagnitudeThreshold: (data['emergencyMagnitudeThreshold'] as num?)?.toDouble() ?? 5.0,
      emergencyRadius: (data['emergencyRadius'] as num?)?.toDouble() ?? 100.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minMagnitude': minMagnitude,
      'notificationsEnabled': notificationsEnabled,
      'radius': radius,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'quietHoursDays': quietHoursDays,
      'emergencyMagnitudeThreshold': emergencyMagnitudeThreshold,
      'emergencyRadius': emergencyRadius,
    };
  }
}
