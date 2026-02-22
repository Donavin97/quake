import 'dart:math';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String _geocodingCacheBox = 'geocodingCache';

class GeocodingService {
  final Dio _dio;
  late final Box<String> _cacheBox;

  GeocodingService({Dio? dio, Box<String>? cacheBox})
      : _dio = dio ?? Dio() {
    _cacheBox = cacheBox ?? Hive.box(_geocodingCacheBox);
  }

  Future<String?> reverseGeocode(double eqLat, double eqLon) async {
    final cacheKey = '${eqLat.toStringAsFixed(5)}_${eqLon.toStringAsFixed(5)}';

    // Try to retrieve from cache first
    final cachedResult = _cacheBox.get(cacheKey);
    if (cachedResult != null) {
      return cachedResult;
    }

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'jsonv2',
          'lat': eqLat.toString(),
          'lon': eqLon.toString(),
          'addressdetails': 1,
          'accept-language': 'en', // Request results in English
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

        String? result;
        if (address != null) {
          String locationName = '';
          String? primaryPlace;

          // Ordered list of keys to check for the most specific "place"
          // Prioritize industrial/amenity/building for features like mines,
          // then smaller populated places, up to larger cities.
          final List<String> placeKeys = [
            'industrial', 'amenity', 'building', 
            'hamlet', 'isolated_dwelling', 'suburb', 'village', 'town', 'city',
            'county', 'state', 'province', 'country'
          ];

          for (final key in placeKeys) {
            if (address.containsKey(key) && address[key] is String && (address[key] as String).isNotEmpty) {
              primaryPlace = address[key];
              break;
            }
          }

          final String finalState = address['county'] ?? address['state'] ?? address['province'] ?? '';
          final String finalCountry = address['country'] ?? '';

          if (primaryPlace != null && primaryPlace.isNotEmpty) {
            locationName = primaryPlace;
            // Append state/province if different from primaryPlace and not empty
            if (finalState.isNotEmpty && !locationName.contains(finalState)) {
              locationName += ', $finalState';
            }
            // Append country if different from state/province and not empty
            if (finalCountry.isNotEmpty && !locationName.contains(finalCountry)) {
              locationName += ', $finalCountry';
            }
          } else if (finalState.isNotEmpty) {
            locationName = finalState;
            if (finalCountry.isNotEmpty && finalCountry != finalState) {
              locationName += ', $finalCountry';
            }
          } else {
            locationName = finalCountry.isNotEmpty ? finalCountry : 'Unknown';
          }

          if (featLat != null && featLon != null) {
            final distance = _calculateDistance(featLat, featLon, eqLat, eqLon);
            if (distance > 1.0) {
              final bearing = _calculateBearing(featLat, featLon, eqLat, eqLon);
              final direction = _bearingToDirection(bearing);
              result = '${distance.toStringAsFixed(0)} km $direction of $locationName';
            }
          }

          result ??= locationName; // Use the constructed locationName
        }
        
        result ??= data['display_name'];

        if (result != null) {
          _cacheBox.put(cacheKey, result);
        }
        return result;
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
