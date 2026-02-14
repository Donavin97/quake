import 'package:dio/dio.dart';

import '../models/earthquake.dart';

class ApiService {
  final _dio = Dio();

  Future<List<Earthquake>> fetchEarthquakes(
      String provider, double minMagnitude, double radius, double? latitude, double? longitude, {String? timeWindow}) async {
    if (provider == 'both') {
      final usgsEarthquakes = await _fetchUsgsEarthquakes(minMagnitude, radius, latitude, longitude, timeWindow: timeWindow);
      final emscEarthquakes = await _fetchEmscEarthquakes(minMagnitude, radius, latitude, longitude, timeWindow: timeWindow);
      return [...usgsEarthquakes, ...emscEarthquakes];
    } else if (provider == 'usgs') {
      return _fetchUsgsEarthquakes(minMagnitude, radius, latitude, longitude, timeWindow: timeWindow);
    } else {
      return _fetchEmscEarthquakes(minMagnitude, radius, latitude, longitude, timeWindow: timeWindow);
    }
  }

  Future<List<Earthquake>> _fetchUsgsEarthquakes(double minMagnitude, double radius, double? latitude, double? longitude, {String? timeWindow}) async {
    try {
      final queryParameters = {
        'format': 'geojson',
        'minmagnitude': minMagnitude.toString(),
        'limit': '100',
        'orderby': 'time',
      };

      if (radius > 0 && latitude != null && longitude != null) {
        queryParameters.addAll({
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'maxradiuskm': radius.toString(),
        });
      }

      final response = await _dio.get(
        'https://earthquake.usgs.gov/fdsnws/event/1/query',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final features = data['features'] as List<dynamic>;
        final earthquakes = features.map((json) => Earthquake.fromUsgsJson(json)).toList();
        return earthquakes;
      } else {
        throw Exception('Failed to load USGS earthquakes');
      }
    } catch (e) {
      throw Exception('Failed to load USGS earthquakes: $e');
    }
  }

  Future<List<Earthquake>> _fetchEmscEarthquakes(double minMagnitude, double radius, double? latitude, double? longitude, {String? timeWindow}) async {
    try {
      final queryParameters = {
        'format': 'json',
        'minmagnitude': minMagnitude.toString(),
        'limit': '100',
        'orderby': 'time',
      };

      if (radius > 0 && latitude != null && longitude != null) {
        queryParameters.addAll({
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'maxradius': (radius / 111.2).toString(), // Convert km to degrees
        });
      }

      final response = await _dio.get(
        'https://www.seismicportal.eu/fdsnws/event/1/query',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final features = data['features'] as List<dynamic>;
        final earthquakes = features.map((json) => Earthquake.fromEmscJson(json)).toList();
        return earthquakes;
      } else {
        throw Exception('Failed to load EMSC earthquakes');
      }
    } catch (e) {
      throw Exception('Failed to load EMSC earthquakes: $e');
    }
  }
}
