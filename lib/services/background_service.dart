import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/earthquake.dart';
import '../models/notification_profile.dart'; // Import
import 'navigation_service.dart';

import '../firebase_options.dart';

// Must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  if (!Hive.isAdapterRegistered(0)) {
    await Hive.initFlutter();
    Hive.registerAdapter(EarthquakeAdapter());
    Hive.registerAdapter(EarthquakeSourceAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(NotificationProfileAdapter());
  }
  
  await Hive.openBox<Earthquake>('earthquakes');
  final Box settingsBox = await Hive.openBox('app_settings');

  // Initialize local notifications for the background isolate
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  
  await BackgroundService.flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  // Ensure notification channel is created in the background isolate
  await BackgroundService.setupNotificationChannel();

  final earthquakeData = message.data['earthquake'] as String?;
  
  if (earthquakeData != null) {
    try {
      final earthquake = Earthquake.fromJson(jsonDecode(earthquakeData));
      if (await BackgroundService.shouldShowNotification(earthquake, settingsBox, data: message.data)) {
        await BackgroundService.showNotification(message);
      }
    } catch (e) {
      debugPrint('Error in background handler: $e');
    }
  }
}

class BackgroundService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static final StreamController<Earthquake> _onEarthquakeReceivedController =
      StreamController<Earthquake>.broadcast();

  static Stream<Earthquake> get onEarthquakeReceived =>
      _onEarthquakeReceivedController.stream;

  static Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;

  static Future<void> setupNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'earthquake_channel',
      'Earthquake Alerts',
      description: 'Notifications for new earthquake events',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('earthquake'),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> initialize() async {
    // Setup local notifications
    await setupNotificationChannel();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.payload == null) return;

        final payloadData = jsonDecode(details.payload!);

        if (details.actionId == 'map_action') {
          final mapUrl = payloadData['mapUrl'] as String?;
          if (mapUrl != null) {
            final uri = Uri.parse(mapUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          }
        } else {
          final earthquake = Earthquake.fromJson(payloadData['earthquake']);
          final context = NavigationService.navigatorKey.currentContext;
          if (context != null) {
            GoRouter.of(context).go('/details/${Uri.encodeComponent(earthquake.id)}');
          }
        }
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final settingsBox = await Hive.openBox('app_settings');
      final earthquakeData = message.data['earthquake'] as String?;
      if (earthquakeData != null) {
        final earthquake = Earthquake.fromJson(jsonDecode(earthquakeData));
        if (await shouldShowNotification(earthquake, settingsBox, data: message.data)) {
           _handleForegroundMessage(message);
        }
      }
    });
  }

  static Future<bool> shouldShowNotification(Earthquake earthquake, Box settingsBox, {Map<String, dynamic>? data}) async {
    final bool notificationsEnabled = settingsBox.get('notificationsEnabled', defaultValue: true);
    if (!notificationsEnabled) return false;

    // Check for duplicates first to save resources
    final earthquakeBox = await Hive.openBox<Earthquake>('earthquakes');
    if (earthquakeBox.containsKey(earthquake.id)) {
      return false; // Already processed this earthquake
    }

    // 0. Server Override (Direct Notification)
    if (data != null && data['isTargeted'] == 'true') {
      return true;
    }

    // 1. Get User Location (Last Known or Current)
    double? userLat = settingsBox.get('lastLatitude') as double?;
    double? userLon = settingsBox.get('lastLongitude') as double?;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 2), accuracy: LocationAccuracy.low),
      );
      userLat = position.latitude;
      userLon = position.longitude;
    } catch (_) {}

    // 2. Load Profiles
    final List<NotificationProfile> profilesToCheck = [];
    final storedProfiles = settingsBox.get('notificationProfiles');

    if (storedProfiles != null && storedProfiles is List && storedProfiles.isNotEmpty) {
      // Cast safely
      profilesToCheck.addAll(storedProfiles.whereType<NotificationProfile>());
    } 
    
    // Fallback: If no profiles found (e.g. legacy data), create a temporary profile from root settings
    if (profilesToCheck.isEmpty) {
      profilesToCheck.add(NotificationProfile(
        id: 'legacy',
        name: 'Legacy Profile',
        latitude: userLat ?? 0.0,
        longitude: userLon ?? 0.0,
        radius: (settingsBox.get('radius', defaultValue: 0.0) as num).toDouble(),
        minMagnitude: (settingsBox.get('minMagnitude', defaultValue: 0) as num).toDouble(),
        quietHoursEnabled: settingsBox.get('quietHoursEnabled', defaultValue: false),
        quietHoursStart: List<int>.from(settingsBox.get('quietHoursStart', defaultValue: [22, 0])),
        quietHoursEnd: List<int>.from(settingsBox.get('quietHoursEnd', defaultValue: [6, 0])),
        quietHoursDays: List<int>.from(settingsBox.get('quietHoursDays', defaultValue: [0, 1, 2, 3, 4, 5, 6])),
        alwaysNotifyRadiusEnabled: settingsBox.get('alwaysNotifyRadiusEnabled', defaultValue: false),
        alwaysNotifyRadiusValue: (settingsBox.get('alwaysNotifyRadiusValue', defaultValue: 0.0) as num).toDouble(),
        emergencyMagnitudeThreshold: (settingsBox.get('emergencyMagnitudeThreshold', defaultValue: 5.0) as num).toDouble(),
        emergencyRadius: (settingsBox.get('emergencyRadius', defaultValue: 100.0) as num).toDouble(),
        globalMinMagnitudeOverrideQuietHours: (settingsBox.get('globalMinMagnitudeOverrideQuietHours', defaultValue: 0.0) as num).toDouble(),
      ));
    }

    // 3. Iterate Profiles
    for (final profile in profilesToCheck) {
      if (_checkProfile(earthquake, profile, userLat, userLon)) {
        return true; // Match found!
      }
    }

    return false;
  }

  static bool _checkProfile(Earthquake earthquake, NotificationProfile profile, double? userLat, double? userLon) {
    // 1. Distance Calculation
    // Use profile location if set, otherwise fallback to user location (mobile profile)
    final double refLat = (profile.latitude != 0.0 || profile.longitude != 0.0) ? profile.latitude : (userLat ?? 0.0);
    final double refLon = (profile.latitude != 0.0 || profile.longitude != 0.0) ? profile.longitude : (userLon ?? 0.0);
    
    final double distance = _getDistance(refLat, refLon, earthquake.latitude, earthquake.longitude);
    
    // 2. Always Notify Checks
    if (profile.globalMinMagnitudeOverrideQuietHours > 0 && earthquake.magnitude >= profile.globalMinMagnitudeOverrideQuietHours) {
        return true;
    }
    if (profile.alwaysNotifyRadiusEnabled && profile.alwaysNotifyRadiusValue > 0 && distance <= profile.alwaysNotifyRadiusValue) {
        return true;
    }

    // 3. Normal Filters
    if (earthquake.magnitude < profile.minMagnitude) return false;
    
    // Radius check: Only if radius > 0 (not worldwide)
    if (profile.radius > 0 && distance > profile.radius) return false;

    // 4. Quiet Hours
    if (profile.quietHoursEnabled) {
        final now = DateTime.now();
        if (_isDuringQuietHoursForProfile(profile, now)) {
             // Emergency Override check
             if (earthquake.magnitude >= profile.emergencyMagnitudeThreshold) {
                 if (distance <= profile.emergencyRadius) return true;
             }
             return false; // Suppressed by quiet hours
        }
    }
    
    return true; // Passed all checks
  }

  static bool _isDuringQuietHoursForProfile(NotificationProfile profile, DateTime now) {
    if (!profile.quietHoursDays.contains(now.weekday % 7)) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = profile.quietHoursStart[0] * 60 + profile.quietHoursStart[1];
    final endMinutes = profile.quietHoursEnd[0] * 60 + profile.quietHoursEnd[1];

    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  static double _getDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degree) => degree * pi / 180;

  static void _handleForegroundMessage(RemoteMessage message) {
    final earthquakeData = message.data['earthquake'] as String?;
    if (earthquakeData != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(earthquakeData);
        final String id = decoded['id'] ?? '';
        final box = Hive.box<Earthquake>('earthquakes');
        
        if (box.containsKey(id)) {
          // If the earthquake is already in the local cache, it was likely
          // already received via the WebSocket or a recent API fetch.
          // We suppress the notification to avoid redundant alerts while using the app.
          return;
        }
      } catch (e) {
        // Fallback to showing notification if parsing fails
      }
    }
    showNotification(message);
  }

  static Future<AuthorizationStatus> requestPermission() async {
    // Always attempt to request permission.
    // This will show the system prompt if permission is not yet granted/explicitly denied.
    // If already granted, it typically just returns 'authorized' without showing a dialog again (OS dependent).
    // If permanently denied, it will return 'denied' without showing a dialog.
    final NotificationSettings settings = await _firebaseMessaging.requestPermission();
    return settings.authorizationStatus;
  }

  static Future<AuthorizationStatus> getNotificationStatus() async {
    final NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  static Future<void> showNotification(RemoteMessage message) async {
    final title = message.data['title'] as String?;
    final body = message.data['body'] as String?;
    final earthquakeData = message.data['earthquake'] as String?;
    final mapUrl = message.data['mapUrl'] as String?;

    if (earthquakeData == null) {
      return;
    }

    final earthquake = Earthquake.fromJson(jsonDecode(earthquakeData));
    
    // Emit through stream for foreground UI updates
    _onEarthquakeReceivedController.add(earthquake);

    final box = Hive.box<Earthquake>('earthquakes');
    await box.put(earthquake.id, earthquake);

    final payload = jsonEncode({
      'earthquake': jsonDecode(earthquakeData),
      'mapUrl': mapUrl,
    });

    // Use different sound for large earthquakes (magnitude >= 6.0)
    final String soundName = earthquake.magnitude >= 6.0 ? 'earthquake-large' : 'earthquake';

    const String groupKey = 'com.quaketrack.EARTHQUAKE_ALERTS';

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'earthquake_channel',
      'Earthquake Alerts',
      channelDescription: 'Notifications for new earthquake events',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      sound: RawResourceAndroidNotificationSound(soundName),
      groupKey: groupKey,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'map_action',
          'View on Map',
        )
      ],
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(
        threadIdentifier: 'earthquake_alerts',
      ),
    );

    // Use a unique ID based on the earthquake's timestamp or hash to prevent overwriting
    final int notificationId = earthquake.id.hashCode;

    await flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );

    // For Android, we also need to send a "summary" notification for the group to appear correctly
    await flutterLocalNotificationsPlugin.show(
      id: 0, // Summary ID is always 0
      title: '',
      body: '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'earthquake_channel',
          'Earthquake Alerts',
          channelDescription: 'Notifications for new earthquake events',
          importance: Importance.max,
          priority: Priority.high,
          groupKey: groupKey,
          setAsGroupSummary: true,
        ),
      ),
    );
  }


  static Future<String?> getFCMToken() async {
    return _firebaseMessaging.getToken();
  }
}
