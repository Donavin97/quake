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
      if (await BackgroundService.shouldShowNotification(earthquake, settingsBox)) {
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
        if (await shouldShowNotification(earthquake, settingsBox)) {
           _handleForegroundMessage(message);
        }
      }
    });
  }

  static Future<bool> shouldShowNotification(Earthquake earthquake, Box settingsBox) async {
    final bool notificationsEnabled = settingsBox.get('notificationsEnabled', defaultValue: true);
    if (!notificationsEnabled) return false;

    // Check for duplicates first to save resources
    final earthquakeBox = await Hive.openBox<Earthquake>('earthquakes');
    if (earthquakeBox.containsKey(earthquake.id)) {
      return false; // Already processed this earthquake
    }

    // 1. Load basic filters
    final double minMagnitude = (settingsBox.get('minMagnitude', defaultValue: 0) as num).toDouble();
    final double radius = (settingsBox.get('radius', defaultValue: 0.0) as num).toDouble();
    
    // 2. Load location and calculate distance
    double? lastLat = settingsBox.get('lastLatitude') as double?;
    double? lastLon = settingsBox.get('lastLongitude') as double?;
    double? distance;

    // Try to get fresh position if possible, but don't hang too long
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 2),
          accuracy: LocationAccuracy.low,
        ),
      );
      lastLat = position.latitude;
      lastLon = position.longitude;
    } catch (_) {
      // Fallback to cached position already loaded above
    }

    if (lastLat != null && lastLon != null) {
      distance = _getDistance(lastLat, lastLon, earthquake.latitude, earthquake.longitude);
    }

    // 3. Load Overrides
    final double globalOverride = (settingsBox.get('globalMinMagnitudeOverrideQuietHours', defaultValue: 0.0) as num).toDouble();
    final bool alwaysNotifyRadiusEnabled = settingsBox.get('alwaysNotifyRadiusEnabled', defaultValue: false);
    final double alwaysNotifyRadiusValue = (settingsBox.get('alwaysNotifyRadiusValue', defaultValue: 0.0) as num).toDouble();

    // 4. CHECK ALWAYS-NOTIFY CRITERIA (These bypass normal minMag and Quiet Hours)
    bool isAlwaysNotify = false;
    
    // Global Magnitude Override (e.g. "Notify me for any 7.0+ regardless of settings")
    if (globalOverride > 0 && earthquake.magnitude >= globalOverride) {
      isAlwaysNotify = true;
    }

    // Local Radius Override (e.g. "Notify me for anything within 50km regardless of settings")
    if (alwaysNotifyRadiusEnabled && alwaysNotifyRadiusValue > 0 && distance != null && distance <= alwaysNotifyRadiusValue) {
      isAlwaysNotify = true;
    }

    if (isAlwaysNotify) return true;

    // 5. NORMAL FILTERS (Magnitude and Radius)
    // If it doesn't meet our basic magnitude criteria, we don't notify.
    if (earthquake.magnitude < minMagnitude) {
      return false;
    }

    // If it's too far away (and we have a radius filter), we don't notify.
    // Note: We "fail open" if distance is unknown (allow it).
    if (radius > 0 && distance != null && distance > radius) {
      return false;
    }

    // 6. QUIET HOURS CHECK
    final bool quietHoursEnabled = settingsBox.get('quietHoursEnabled', defaultValue: false);
    if (quietHoursEnabled) {
      final now = DateTime.now();
      if (_isDuringQuietHours(settingsBox, now)) {
        // We ARE in quiet hours. Only allow if it's an "Emergency".
        final double emergencyMag = (settingsBox.get('emergencyMagnitudeThreshold', defaultValue: 5.0) as num).toDouble();
        final double emergencyRad = (settingsBox.get('emergencyRadius', defaultValue: 100.0) as num).toDouble();
        
        // Emergency criteria: magnitude is high enough AND (distance is close or unknown)
        if (earthquake.magnitude >= emergencyMag) {
          if (distance == null || distance <= emergencyRad) {
            return true;
          }
        }
        
        // If it's quiet hours and NOT an emergency (and NOT an Always-Notify from step 4), silence it.
        return false;
      }
    }

    // 7. If we reached here, it passed all filters and it's NOT quiet hours.
    return true;
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

  static bool _isDuringQuietHours(Box settingsBox, DateTime now) {
    final List<int> start = List<int>.from(settingsBox.get('quietHoursStart', defaultValue: [22, 0]));
    final List<int> end = List<int>.from(settingsBox.get('quietHoursEnd', defaultValue: [6, 0]));
    final List<int> days = List<int>.from(settingsBox.get('quietHoursDays', defaultValue: [0, 1, 2, 3, 4, 5, 6]));

    if (!days.contains(now.weekday % 7)) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = start[0] * 60 + start[1];
    final endMinutes = end[0] * 60 + end[1];

    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

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
    NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      return AuthorizationStatus.authorized; // Already granted
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // User has denied permanently. We cannot request again from here.
      // The UI should guide the user to app settings.
      return AuthorizationStatus.denied;
    }

    // AuthorizationStatus.notDetermined or AuthorizationStatus.provisional or others
    settings = await _firebaseMessaging.requestPermission();
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

    const String groupKey = 'com.quaketrack.EARTHQUAKE_ALERTS';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'earthquake_channel',
      'Earthquake Alerts',
      channelDescription: 'Notifications for new earthquake events',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      sound: RawResourceAndroidNotificationSound('earthquake'),
      groupKey: groupKey,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'map_action',
          'View on Map',
        )
      ],
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
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
