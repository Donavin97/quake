import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  
  if (!Hive.isBoxOpen('earthquakes')) {
    await Hive.openBox<Earthquake>('earthquakes');
  }

  if (!Hive.isBoxOpen('app_settings')) {
    await Hive.openBox('app_settings');
  }

  // Initialize local notifications for the background isolate
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  
  await BackgroundService.flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  final settingsBox = Hive.box('app_settings');
  final earthquakeData = message.data['earthquake'] as String?;
  
  if (earthquakeData != null) {
    final earthquake = Earthquake.fromJson(jsonDecode(earthquakeData));
    if (await BackgroundService.shouldShowNotification(earthquake, settingsBox)) {
      await BackgroundService.showNotification(message);
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

  static Future<void> initialize() async {
    // Setup local notifications
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
            GoRouter.of(context).go('/details/${earthquake.id}', extra: earthquake);
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

    final double minMagnitude = (settingsBox.get('minMagnitude', defaultValue: 0) as num).toDouble();
    final double radius = (settingsBox.get('radius', defaultValue: 0.0) as num).toDouble();
    
    // 1. Global Override Check
    final double globalOverride = (settingsBox.get('globalMinMagnitudeOverrideQuietHours', defaultValue: 0.0) as num).toDouble();
    if (globalOverride > 0 && earthquake.magnitude >= globalOverride) {
      return true;
    }

    // Get current position for distance-based filters
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      // If we can't get position, we might want to skip distance filters or allow them
    }

    double? distance;
    if (position != null) {
      distance = _getDistance(position.latitude, position.longitude, earthquake.latitude, earthquake.longitude);
    }

    // 2. Always Notify Radius Check
    final bool alwaysNotifyEnabled = settingsBox.get('alwaysNotifyRadiusEnabled', defaultValue: false);
    final double alwaysNotifyValue = (settingsBox.get('alwaysNotifyRadiusValue', defaultValue: 0.0) as num).toDouble();
    if (alwaysNotifyEnabled && alwaysNotifyValue > 0 && distance != null && distance <= alwaysNotifyValue) {
      return true;
    }

    // 3. Magnitude Check
    if (earthquake.magnitude < minMagnitude) {
      return false;
    }

    // 4. Radius Check
    if (radius > 0 && distance != null && distance > radius) {
      return false;
    }

    // 5. Quiet Hours Check
    final bool quietHoursEnabled = settingsBox.get('quietHoursEnabled', defaultValue: false);
    if (quietHoursEnabled) {
      final now = DateTime.now();
      if (_isDuringQuietHours(settingsBox, now)) {
        final double emergencyMag = (settingsBox.get('emergencyMagnitudeThreshold', defaultValue: 5.0) as num).toDouble();
        final double emergencyRad = (settingsBox.get('emergencyRadius', defaultValue: 100.0) as num).toDouble();
        
        if (earthquake.magnitude >= emergencyMag && distance != null && distance <= emergencyRad) {
          return true;
        }
        return false;
      }
    }

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

  static Future<void> requestPermission() async {
    await _firebaseMessaging.requestPermission();
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
