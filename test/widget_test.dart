
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:quaketrack/main.dart';
import 'package:quaketrack/notification_service.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([NotificationService])
void main() {
  testWidgets('App builds and displays home screen', (WidgetTester tester) async {
    // Create a mock NotificationService
    final mockNotificationService = MockNotificationService();

    // When the init method is called, do nothing
    when(mockNotificationService.init()).thenAnswer((_) async => {});

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      notificationService: mockNotificationService,
    ));

    // Wait for all animations to complete.
    await tester.pumpAndSettle();

    // Verify that the home screen is displayed.
    expect(find.text('QuakeTrack'), findsOneWidget);
  });
}
