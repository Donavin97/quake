import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/earthquake.dart';

class EmscService {
  static const String _baseUrl =
      'https://www.seismicportal.eu/fdsnws/event/1/query';

  Future<List<EmscEarthquake>> fetchEarthquakes({
    double? latitude,
    double? longitude,
    double? maxRadius, // in degrees
    String? startTime,
    int? limit,
  }) async {
    final queryParameters = {
      'format': 'json',
      if (latitude != null) 'lat': latitude.toString(),
      if (longitude != null) 'lon': longitude.toString(),
      if (maxRadius != null) 'maxradius': maxRadius.toString(),
      if (startTime != null) 'start': startTime,
      if (limit != null) 'limit': limit.toString(),
    };

    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParameters);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'] as List;
      return features.map((e) => EmscEarthquake.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load earthquakes');
    }
  }
}
