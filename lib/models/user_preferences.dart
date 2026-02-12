class UserPreferences {
  final double minMagnitude;
  final bool notificationsEnabled;

  UserPreferences({
    this.minMagnitude = 4.5,
    this.notificationsEnabled = true,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> data) {
    return UserPreferences(
      minMagnitude: (data['minMagnitude'] as num?)?.toDouble() ?? 4.5,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minMagnitude': minMagnitude,
      'notificationsEnabled': notificationsEnabled,
    };
  }
}
