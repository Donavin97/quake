import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:quaketrack/main.dart';
import 'package:quaketrack/models/earthquake.dart';
import 'package:quaketrack/services/services.dart';
import 'package:quaketrack/widgets/earthquake_list_item.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([NotificationService])
void main() {
  testWidgets('App builds and displays home screen', (WidgetTester tester) async {
    // Create a mock NotificationService
    final mockNotificationService = MockNotificationService();

    // When the init method is called, do nothing
    when(mockNotificationService.initialize()).thenAnswer((_) async => {});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for all animations to complete.
    await tester.pumpAndSettle();

    // Verify that the home screen is displayed.
    expect(find.text('QuakeTrack'), findsOneWidget);
  });

  testWidgets('EarthquakeListItem displays correct data', (WidgetTester tester) async {
    // Create a mock Earthquake object
    final earthquake = Earthquake(
        id: 'test_id',
        magnitude: 5.6,
        place: 'Test Location',
        time: DateTime.now(),
        latitude: 0.0,
        longitude: 0.0,
        source: EarthquakeSource.usgs,
        provider: 'usgs');

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EarthquakeListItem(earthquake: earthquake),
        ),
      ),
    );

    // Verify that the magnitude, place, and time are displayed correctly
    expect(find.text('5.6'), findsOneWidget);
    expect(find.text('Test Location'), findsOneWidget);
    expect(find.text(DateFormat.yMMMd().add_jms().format(earthquake.time)), findsOneWidget);
  });
}
