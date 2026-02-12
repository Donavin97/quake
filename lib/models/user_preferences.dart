class UserPreferences {
  final double minMagnitude;
  final bool notificationsEnabled;
  final double radius;

  UserPreferences({
    this.minMagnitude = 4.5,
    this.notificationsEnabled = true,
    this.radius = 0,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> data) {
    return UserPreferences(
      minMagnitude: (data['minMagnitude'] as num?)?.toDouble() ?? 4.5,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      radius: (data['radius'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minMagnitude': minMagnitude,
      'notificationsEnabled': notificationsEnabled,
      'radius': radius,
    };
  }
}
