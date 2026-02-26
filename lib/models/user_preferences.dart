import 'notification_profile.dart'; // Import the new NotificationProfile model
import 'time_window.dart'; // Import TimeWindow for global setting

class UserPreferences {
  final bool notificationsEnabled;
  final List<NotificationProfile> notificationProfiles; // New field for multiple profiles

  // Truly global settings not tied to a specific notification profile
  final int themeMode; // ThemeMode.index
  final TimeWindow timeWindow;
  final String earthquakeProvider;
  final List<String> subscribedTopics;

  UserPreferences({
    this.notificationsEnabled = true,
    List<NotificationProfile>? notificationProfiles,
    this.themeMode = 0, // Default to system theme
    this.timeWindow = TimeWindow.day,
    this.earthquakeProvider = 'usgs',
    this.subscribedTopics = const [],
  }) : notificationProfiles = notificationProfiles ?? [];

  factory UserPreferences.fromMap(Map<String, dynamic> data) {
    List<NotificationProfile> profiles = [];
    if (data['notificationProfiles'] != null) {
      profiles = (data['notificationProfiles'] as List)
          .map((i) => NotificationProfile.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    // Backward compatibility: if no profiles exist, create one from old settings
    if (profiles.isEmpty) {
      profiles.add(NotificationProfile(
        id: 'default', // Assign a default ID
        name: 'Default Profile',
        latitude: (data['location']?['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (data['location']?['longitude'] as num?)?.toDouble() ?? 0.0,
        radius: (data['radius'] as num?)?.toDouble() ?? 0,
        minMagnitude: (data['minMagnitude'] as num?)?.toDouble() ?? 4.5,
        quietHoursEnabled: data['quietHoursEnabled'] as bool? ?? false,
        quietHoursStart: (data['quietHoursStart'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [22, 0],
        quietHoursEnd: (data['quietHoursEnd'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [6, 0],
        quietHoursDays: (data['quietHoursDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [0, 1, 2, 3, 4, 5, 6],
        alwaysNotifyRadiusEnabled: data['alwaysNotifyRadiusEnabled'] as bool? ?? false,
        alwaysNotifyRadiusValue: (data['alwaysNotifyRadiusValue'] as num?)?.toDouble() ?? 0.0,
        emergencyMagnitudeThreshold: (data['emergencyMagnitudeThreshold'] as num?)?.toDouble() ?? 5.0,
        emergencyRadius: (data['emergencyRadius'] as num?)?.toDouble() ?? 100.0,
      ));
    }

    return UserPreferences(
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      notificationProfiles: profiles,
      themeMode: data['themeMode'] as int? ?? 0,
      timeWindow: TimeWindow.values[data['timeWindow'] as int? ?? 0],
      earthquakeProvider: data['earthquakeProvider'] as String? ?? 'usgs',
      subscribedTopics: (data['subscribedTopics'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'notificationProfiles': notificationProfiles.map((p) => p.toJson()).toList(),
      'themeMode': themeMode,
      'timeWindow': timeWindow.index,
      'earthquakeProvider': earthquakeProvider,
      'subscribedTopics': subscribedTopics,
    };
  }

  UserPreferences copyWith({
    bool? notificationsEnabled,
    List<NotificationProfile>? notificationProfiles,
    int? themeMode,
    TimeWindow? timeWindow,
    String? earthquakeProvider,
    List<String>? subscribedTopics,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationProfiles: notificationProfiles ?? [...this.notificationProfiles],
      themeMode: themeMode ?? this.themeMode,
      timeWindow: timeWindow ?? this.timeWindow,
      earthquakeProvider: earthquakeProvider ?? this.earthquakeProvider,
      subscribedTopics: subscribedTopics ?? [...this.subscribedTopics],
    );
  }
}
