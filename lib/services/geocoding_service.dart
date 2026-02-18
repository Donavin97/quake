import 'package:dio/dio.dart';

class GeocodingService {
  final Dio _dio;

  GeocodingService({Dio? dio}) : _dio = dio ?? Dio();

  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'zoom': 10,
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
        if (address != null) {
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'];
          final state = address['state'] ?? address['province'];
          final country = address['country'];

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
}
