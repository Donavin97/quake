import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/earthquake.dart';
import 'navigation_service.dart';

// Must be a top-level function (not a class method)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  await Hive.initFlutter();
  Hive.registerAdapter(EarthquakeAdapter());
  Hive.registerAdapter(EarthquakeSourceAdapter());
  await Hive.openBox<Earthquake>('earthquakes');

  BackgroundService.showNotification(message);
}

class BackgroundService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Setup local notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'earthquake_channel',
      'Earthquake Alerts',
      description: 'Notifications for new earthquake events',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('earthquake'),
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
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

    // Setup FCM
    await _firebaseMessaging.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotification(message);
    });
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
    final box = Hive.box<Earthquake>('earthquakes');
    await box.put(earthquake.id, earthquake);

    final payload = jsonEncode({
      'earthquake': jsonDecode(earthquakeData),
      'mapUrl': mapUrl,
    });

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'earthquake_channel',
      'Earthquake Alerts',
      channelDescription: 'Notifications for new earthquake events',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      sound: RawResourceAndroidNotificationSound('earthquake'),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'map_action',
          'View on Map',
        )
      ],
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  static Future<String?> getFCMToken() async {
    return _firebaseMessaging.getToken();
  }
}
