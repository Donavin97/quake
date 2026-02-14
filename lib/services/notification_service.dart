import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dart_geohash/dart_geohash.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Set<String> _currentGeohashTopics = {};
  int _currentMagnitude = -1;

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();
    await _firebaseMessaging.getToken();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> updateSubscriptions({
    required double latitude,
    required double longitude,
    required double radius,
    required int magnitude,
  }) async {
    // Unsubscribe from old geohash topics
    for (final topic in _currentGeohashTopics) {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    }
    _currentGeohashTopics.clear();

    // Unsubscribe from old magnitude topics
    if (_currentMagnitude != magnitude) {
      for (int i = 0; i <= 10; i++) {
        await _firebaseMessaging.unsubscribeFromTopic('minmag_$i');
      }
    }

    if (magnitude >= 0) {
      // Subscribe to new magnitude topics
      for (int i = 0; i <= magnitude; i++) {
        await _firebaseMessaging.subscribeToTopic('minmag_$i');
      }
      _currentMagnitude = magnitude;
    }

    if (radius > 0) {
      // Subscribe to new geohash topics
      final precision = _getGeohashPrecision(radius);
      final geoHasher = GeoHasher();
      final centerGeohash = geoHasher.encode(latitude, longitude, precision: precision);
      final geohashes = geoHasher.neighbors(centerGeohash).values.toList()..add(centerGeohash);

      for (final geohash in geohashes) {
        await _firebaseMessaging.subscribeToTopic(geohash);
        _currentGeohashTopics.add(geohash);
      }
    }
  }

  int _getGeohashPrecision(double radius) {
    if (radius <= 0.07) return 6; // Up to 70m
    if (radius <= 0.6) return 5; // Up to 600m
    if (radius <= 2.4) return 4; // Up to 2.4km
    if (radius <= 20) return 3; // Up to 20km
    if (radius <= 78) return 2; // Up to 78km
    return 1; // Up to 630km
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
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
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data['earthquakeId'],
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
}
