import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
      'main_channel',
      'Main Channel',
      description: 'Main notification channel',
      importance: Importance.max,
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
        // Handle notification tap
        if (details.payload != null) {
          final earthquake = Earthquake.fromJson(jsonDecode(details.payload!));
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
    final earthquake = Earthquake.fromJson(message.data);
    final title = '${earthquake.magnitude} Magnitude Earthquake';
    final body = earthquake.place;
    final payload = jsonEncode(earthquake.toJson());

    final box = Hive.box<Earthquake>('earthquakes');
    await box.put(earthquake.id, earthquake);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'main_channel',
      'Main Channel',
      channelDescription: 'Main notification channel',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
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
