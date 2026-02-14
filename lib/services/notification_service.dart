import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geohash_plus/geohash_plus.dart';

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
      final centerGeohash = Geohash.encode(latitude, longitude, precision: 5);
      final neighbors = Geohash.neighbors(centerGeohash);
      
      final Set<String> newGeohashTopics = {centerGeohash, ...neighbors.values};

      for (final geohash in newGeohashTopics) {
        await _firebaseMessaging.subscribeToTopic(geohash);
        _currentGeohashTopics.add(geohash);
      }
    }
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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
}
