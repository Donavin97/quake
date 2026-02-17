import 'dart:io';

import 'package:dio/dio.dart';

import '../models/earthquake.dart';
import '../exceptions/api_exception.dart'; // New import

class ApiService {
  final _dio = Dio();

  // Helper function to parse time window
  Duration _parseTimeWindow(String timeWindow) {
    switch (timeWindow) {
      case 'hour':
        return const Duration(hours: 1);
      case 'day':
        return const Duration(days: 1);
      case 'week':
        return const Duration(days: 7);
      case 'month':
        return const Duration(days: 30);
      default:
        return const Duration(days: 1); // Default to day
    }
  }

  ApiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      final errorMessage = error.response?.data != null && error.response?.data is Map
          ? error.response?.data['message'] ?? 'An error occurred'
          : 'An error occurred';
      switch (statusCode) {
        case 400:
          return BadRequestException(errorMessage, statusCode: statusCode);
        case 401:
          return UnauthorizedException(errorMessage, statusCode: statusCode);
        case 403:
          return ForbiddenException(errorMessage, statusCode: statusCode);
        case 404:
          return NotFoundException(errorMessage, statusCode: statusCode);
        case 500:
          return InternalServerErrorException(errorMessage, statusCode: statusCode);
        default:
          return UnknownApiException('Received invalid status code: $statusCode');
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return TimeoutException('Connection timed out. Please try again.');
    } else if (error.error is SocketException) {
      return NetworkException('No internet connection. Please check your network settings.');
    } else if (error.type == DioExceptionType.cancel) {
      return UnknownApiException('Request was cancelled.');
    } else {
      return UnknownApiException('An unknown error occurred: ${error.message}');
    }
  }

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

      if (timeWindow != null) {
        final duration = _parseTimeWindow(timeWindow);
        queryParameters['starttime'] = DateTime.now().subtract(duration).toIso8601String();
        queryParameters['endtime'] = DateTime.now().toIso8601String();
      }

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
        throw ApiException('Failed to load USGS earthquakes: Unexpected status code', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownApiException('An unexpected error occurred: $e');
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

      if (timeWindow != null) {
        final duration = _parseTimeWindow(timeWindow);
        queryParameters['starttime'] = DateTime.now().subtract(duration).toIso8601String();
        queryParameters['endtime'] = DateTime.now().toIso8601String();
      }

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
        throw ApiException('Failed to load EMSC earthquakes: Unexpected status code', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnknownApiException('An unexpected error occurred: $e');
    }
  }
}
