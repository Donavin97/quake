import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:get/get.dart';

import '../models/earthquake.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Set<String> _currentTopics = {};

  Future<void> initialize() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'earthquake_channel',
      'Earthquake Notifications',
      description: 'Notifications for new earthquakes',
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
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          final earthquake = Earthquake.fromJson(jsonDecode(response.payload!));
          Get.toNamed('/detail', arguments: earthquake);
        }
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> requestPermission() async {
    await _firebaseMessaging.requestPermission();
  }

  Future<void> updateSubscriptions({
    double? latitude,
    double? longitude,
    double? radius,
    required int magnitude,
  }) async {
    final newTopics = <String>{};

    newTopics.add('minmag_$magnitude');

    if (radius != null && radius > 0 && latitude != null && longitude != null) {
      newTopics.addAll(_calculateGeohashTopics(latitude, longitude, radius));
    } else {
      newTopics.add('global');
    }

    final topicsToUnsubscribe = _currentTopics.difference(newTopics);
    final topicsToSubscribe = newTopics.difference(_currentTopics);

    for (final topic in topicsToUnsubscribe) {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    }

    for (final topic in topicsToSubscribe) {
      await _firebaseMessaging.subscribeToTopic(topic);
    }

    _currentTopics.clear();
    _currentTopics.addAll(newTopics);
  }

  Set<String> _calculateGeohashTopics(double latitude, double longitude, double radius) {
    final int precision = _getGeohashPrecision(radius);
    final geoHasher = GeoHasher();
    final centerGeohash = geoHasher.encode(longitude, latitude, precision: precision);
    final neighbors = geoHasher.neighbors(centerGeohash);

    final topics = <String>{centerGeohash};
    topics.addAll(neighbors.values.whereType<String>());
    return topics;
  }

  int _getGeohashPrecision(double radius) {
    if (radius <= 0.1) return 9;
    if (radius <= 0.5) return 8;
    if (radius <= 2) return 7;
    if (radius <= 10) return 6;
    if (radius <= 40) return 5;
    if (radius <= 150) return 4;
    if (radius <= 600) return 3;
    if (radius <= 2500) return 2;
    return 1;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final String? title = message.notification?.title ?? message.data['title'];
    final String? body = message.notification?.body ?? message.data['body'];

    if (title == null || body == null) {
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'earthquake_channel',
      'Earthquake Notifications',
      channelDescription: 'Notifications for new earthquakes',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('earthquake'),
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: message.data['earthquake'],
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.notification != null) {
    return;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'earthquake_channel',
    'Earthquake Notifications',
    description: 'Notifications for new earthquakes',
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
    initializationSettings,
  );

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'earthquake_channel',
    'Earthquake Notifications',
    channelDescription: 'Notifications for new earthquakes',
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('earthquake'),
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    message.data['title'],
    message.data['body'],
    platformChannelSpecifics,
    payload: message.data['earthquake'],
  );
}
