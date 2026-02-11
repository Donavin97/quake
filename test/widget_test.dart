import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quaketrack/main.dart';
import 'package:quaketrack/notification_service.dart';

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
  testWidgets('App builds and displays home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      notificationService: MockNotificationService(),
    ));

    // Wait for all animations to complete.
    await tester.pumpAndSettle();

    // Verify that the home screen is displayed.
    expect(find.text('QuakeTrack'), findsOneWidget);
  });
}
