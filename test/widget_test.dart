import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/notification_service.dart';

class MockNotificationService implements NotificationService {
  @override
  bool get isPermissionGranted => false;

  @override
  Future<void> init() async {
    // Mock implementation
  }

  @override
  Future<void> checkPermission() async {
    // Mock implementation
  }

  @override
  Future<void> requestPermission() async {
    // Mock implementation
  }

  @override
  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) {
    // Mock implementation
  }

  @override
  Future<void> showNotification(
      {required int id,
      required String title,
      required String body,
      required String payload}) async {
    // Mock implementation
  }
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(notificationService: MockNotificationService()));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
