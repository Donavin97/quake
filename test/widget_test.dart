import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:quaketrack/models/earthquake.dart';
import 'package:quaketrack/widgets/earthquake_list_item.dart';

void main() {
  testWidgets('EarthquakeListItem displays correct data', (WidgetTester tester) async {
    // Create a mock Earthquake object
    final earthquake = Earthquake(
        id: 'test_id',
        magnitude: 5.6,
        place: 'Test Location',
        time: DateTime(2026, 3, 6, 12),
        latitude: 0.0,
        longitude: 0.0,
        depth: 10.0,
        source: EarthquakeSource.usgs,
        provider: 'usgs',
        distance: 5000.0, // 5km
    );

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EarthquakeListItem(earthquake: earthquake),
        ),
      ),
    );

    // Verify that the magnitude, place, and time are displayed correctly
    expect(find.text('Test Location'), findsOneWidget);
    expect(find.text('Magnitude: 5.6'), findsOneWidget);
    expect(find.textContaining('5.00 km'), findsOneWidget);
    
    final formattedDate = DateFormat.yMMMd().format(earthquake.time.toLocal());
    expect(find.textContaining(formattedDate), findsOneWidget);
  });
}
