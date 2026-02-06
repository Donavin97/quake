import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/earthquake.dart';

class UsgsService {
  static const String _baseUrl =
      'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson';

  Future<List<Earthquake>> getRecentEarthquakes() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'] as List;
      return features.map((feature) => Earthquake.fromJson(feature)).toList();
    } else {
      throw Exception('Failed to load earthquakes');
    }
  }
}
