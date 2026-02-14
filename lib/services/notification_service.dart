import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dart_geohash/dart_geohash.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Set<String> _currentGeohashTopics = {};
  int _currentMagnitude = -1;
  bool _isSubscribedToGlobal = false;

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();

    // Create the Android Notification Channel
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
    await _unsubscribeFromAllTopics();

    if (magnitude >= 0) {
      await _firebaseMessaging.subscribeToTopic('minmag_$magnitude');
      _currentMagnitude = magnitude;
    }

    if (radius == 0) {
      await _firebaseMessaging.subscribeToTopic('global');
      _isSubscribedToGlobal = true;
    } else {
      final newGeohashTopics = _calculateGeohashTopics(latitude, longitude, radius);
      for (final topic in newGeohashTopics) {
        await _firebaseMessaging.subscribeToTopic(topic);
      }
      _currentGeohashTopics.clear();
      _currentGeohashTopics.addAll(newGeohashTopics);
    }
  }

  Future<void> _unsubscribeFromAllTopics() async {
    for (final topic in _currentGeohashTopics) {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    }
    _currentGeohashTopics.clear();

    if (_currentMagnitude != -1) {
      await _firebaseMessaging.unsubscribeFromTopic('minmag_$_currentMagnitude');
    }
    if (_isSubscribedToGlobal) {
      await _firebaseMessaging.unsubscribeFromTopic('global');
      _isSubscribedToGlobal = false;
    }
  }

  Set<String> _calculateGeohashTopics(double latitude, double longitude, double radius) {
    final geoHasher = GeoHasher();
    final centerGeohash = geoHasher.encode(longitude, latitude, precision: 4);
    final neighbors = geoHasher.neighbors(centerGeohash);

    final topics = <String>{centerGeohash};
    topics.addAll(neighbors.values);
    return topics;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
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
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data['earthquakeId'],
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handling
}
