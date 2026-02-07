import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/earthquake.dart';

class UsgsService {
  Future<List<Earthquake>> getRecentEarthquakes() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final startTime = yesterday.toUtc().toIso8601String();
    final endTime = now.toUtc().toIso8601String();

    final url =
        'https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=$startTime&endtime=$endTime';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        return features.map((feature) => Earthquake.fromJson(feature)).toList();
      } else {
        throw Exception('Failed to load earthquakes');
      }
    } catch (e) {
      // Return mock data if fetching fails
      return _getMockEarthquakes();
    }
  }

  List<Earthquake> _getMockEarthquakes() {
    return [
      Earthquake(
        id: 'mock1',
        place: 'San Francisco, California',
        time: DateTime.now(),
        magnitude: 4.5,
        latitude: 37.7749,
        longitude: -122.4194,
        depth: 10.0,
      ),
      Earthquake(
        id: 'mock2',
        place: 'Tokyo, Japan',
        time: DateTime.now().subtract(const Duration(hours: 2)),
        magnitude: 5.2,
        latitude: 35.6895,
        longitude: 139.6917,
        depth: 25.0,
      ),
      Earthquake(
        id: 'mock3',
        place: 'Santiago, Chile',
        time: DateTime.now().subtract(const Duration(hours: 5)),
        magnitude: 6.1,
        latitude: -33.4489,
        longitude: -70.6693,
        depth: 70.0,
      ),
    ];
  }
}
