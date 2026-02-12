import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/earthquake.dart';
import '../models/time_window.dart';

class UsgsService {
  Future<List<Earthquake>> getRecentEarthquakes({
    TimeWindow timeWindow = TimeWindow.day,
    double minMagnitude = 0.0,
    double radius = 1000.0,
    Position? position,
  }) async {
    final now = DateTime.now();
    final startTime = _getStartTime(now, timeWindow);

    final queryParameters = {
      'format': 'geojson',
      'starttime': startTime,
      'endtime': now.toUtc().toIso8601String(),
      'minmagnitude': minMagnitude.toString(),
    };

    if (position != null && radius > 0.0) {
      queryParameters.addAll({
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'maxradiuskm': radius.toString(),
      });
    }

    final uri = Uri.https('earthquake.usgs.gov', '/fdsnws/event/1/query', queryParameters);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        return features.map((feature) => Earthquake.fromJson(feature)).toList();
      } else {
        throw Exception('Failed to load earthquakes');
      }
    } catch (e) {
      throw Exception('Failed to load earthquakes: $e');
    }
  }

  String _getStartTime(DateTime now, TimeWindow timeWindow) {
    switch (timeWindow) {
      case TimeWindow.day:
        return now.subtract(const Duration(days: 1)).toUtc().toIso8601String();
      case TimeWindow.week:
        return now.subtract(const Duration(days: 7)).toUtc().toIso8601String();
      case TimeWindow.month:
        return now.subtract(const Duration(days: 30)).toUtc().toIso8601String();
    }
  }
}
