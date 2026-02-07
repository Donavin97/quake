import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_service.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  developer.log('Handling a background message ${message.messageId}');
  developer.log('Title: ${message.notification?.title}');
  developer.log('Body: ${message.notification?.body}');
  developer.log('Payload: ${message.data}');
  NotificationService().showNotification(
    0, // id
    message.notification?.title ?? '',
    message.notification?.body ?? '',
    message.data.toString(),
  );
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    developer.log('FCM Token: $fCMToken');
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen(handleMessage);
  }

  void handleMessage(RemoteMessage message) {
    developer.log('Got a message whilst in the foreground!');
    developer.log('Message data: ${message.data}');

    if (message.notification != null) {
      developer.log('Message also contained a notification: ${message.notification}');
      NotificationService().showNotification(
        1, // id
        message.notification?.title ?? '',
        message.notification?.body ?? '',
        message.data.toString(),
      );
    }
  }
}
