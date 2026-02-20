import 'dart:math';
import 'package:dio/dio.dart';

class GeocodingService {
  final Dio _dio;

  GeocodingService({Dio? dio}) : _dio = dio ?? Dio();

  Future<String?> reverseGeocode(double eqLat, double eqLon) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': eqLat.toString(),
          'lon': eqLon.toString(),
          'zoom': 13,
          'addressdetails': 1,
        },
        options: Options(
          headers: {
            'User-Agent': 'QuakeTrackApp/1.0',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final address = data['address'];
        final featLat = double.tryParse(data['lat']?.toString() ?? '');
        final featLon = double.tryParse(data['lon']?.toString() ?? '');

        if (address != null) {
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'];
          final state = address['state'] ?? address['province'] ?? address['county'];
          final country = address['country'];

          String locationName = '';
          if (city != null && state != null) {
            locationName = '$city, $state';
          } else if (state != null) {
            locationName = '$state';
          } else {
            locationName = country ?? 'Unknown';
          }

          if (featLat != null && featLon != null) {
            final distance = _calculateDistance(featLat, featLon, eqLat, eqLon);
            if (distance > 1.0) {
              final bearing = _calculateBearing(featLat, featLon, eqLat, eqLon);
              final direction = _bearingToDirection(bearing);
              return '${distance.toStringAsFixed(0)} km $direction of $locationName, $country';
            }
          }

          if (city != null && state != null) {
            return '$city, $state, $country';
          } else if (state != null) {
            return '$state, $country';
          } else {
            return country;
          }
        }
        return data['display_name'];
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final y = sin(dLon) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  String _bearingToDirection(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) % 360 / 45).floor();
    return directions[index];
  }
}
