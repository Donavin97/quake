import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

// Must be a top-level function
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  developer.log('Handling a background message ${message.messageId}');

  final prefs = await SharedPreferences.getInstance();
  final minMagnitude = prefs.getDouble('minMagnitude') ?? 0.0;
  final radius = prefs.getDouble('radius') ?? 1000.0;
  final earthquakeMagnitude = double.parse(message.data['magnitude'] ?? '0.0');

  if (earthquakeMagnitude >= minMagnitude) {
    final earthquakeLat = double.parse(message.data['lat'] ?? '0.0');
    final earthquakeLng = double.parse(message.data['lng'] ?? '0.0');

    try {
      final position = await Geolocator.getCurrentPosition();
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        earthquakeLat,
        earthquakeLng,
      );

      if (distance <= radius * 1000) {
        if (message.notification != null) {
          developer.log(
              'Message also contained a notification: ${message.notification}');
          final notificationService = NotificationService();
          notificationService.showNotification(
            id: message.hashCode,
            title: message.notification?.title ?? '',
            body: message.notification?.body ?? '',
            payload: message.data.toString(),
          );
        }
      }
    } catch (e) {
      developer.log('Error getting user location in background: $e');
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isPermissionGranted = false;

  bool get isPermissionGranted => _isPermissionGranted;

  Future<void> init() async {
    // Init local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // Handle token updates
    _firebaseMessaging.onTokenRefresh.listen((fcmToken) {
      _saveTokenToFirestore(fcmToken);
    });

    // Handle user authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _firebaseMessaging.getToken().then((fcmToken) {
          _saveTokenToFirestore(fcmToken);
        });
      }
    });

    // Init Firebase Messaging
    final fCMToken = await _firebaseMessaging.getToken();
    developer.log('FCM Token: $fCMToken');
    _saveTokenToFirestore(fCMToken);
    _firebaseMessaging.subscribeToTopic('all');

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      developer.log('Got a message whilst in the foreground!');

      final prefs = await SharedPreferences.getInstance();
      final minMagnitude = prefs.getDouble('minMagnitude') ?? 0.0;
      final radius = prefs.getDouble('radius') ?? 1000.0;
      final earthquakeMagnitude =
          double.parse(message.data['magnitude'] ?? '0.0');

      if (earthquakeMagnitude >= minMagnitude) {
        final earthquakeLat = double.parse(message.data['lat'] ?? '0.0');
        final earthquakeLng = double.parse(message.data['lng'] ?? '0.0');

        try {
          final position = await Geolocator.getCurrentPosition();
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            earthquakeLat,
            earthquakeLng,
          );

          if (distance <= radius * 1000) {
            if (message.notification != null) {
              developer.log(
                  'Message also contained a notification: ${message.notification}');
              showNotification(
                id: message.hashCode,
                title: message.notification?.title ?? '',
                body: message.notification?.body ?? '',
                payload: message.data.toString(),
              );
            }
          }
        } catch (e) {
          developer.log('Error getting user location in foreground: $e');
        }
      }
    });
  }

  Future<void> checkPermission() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('notification_permission_granted') ?? false) {
      _isPermissionGranted = true;
      return;
    }
    final settings = await _firebaseMessaging.getNotificationSettings();
    _isPermissionGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<void> requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission();
    _isPermissionGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'notification_permission_granted', _isPermissionGranted);
  }

  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    // Handle notification tap
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'main_channel',
      'Main Channel',
      channelDescription: 'Main channel notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('earthquake'),
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> _saveTokenToFirestore(String? token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || token == null) return;
    await _firestore.collection('user_fcm_tokens').doc(user.uid).set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
