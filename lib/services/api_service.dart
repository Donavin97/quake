import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Added this import

import '../models/earthquake.dart';
import '../exceptions/api_exception.dart'; // New import

class ApiService {
  final Dio _dio;

  ApiService({Dio? dio}) : _dio = dio ?? Dio();

  static const _usgsUrl = 'https://earthquake.usgs.gov/fdsnws/event/1/query';
  static const _emscUrl = 'https://www.seismicportal.eu/fdsnws/event/1/query';
  static const _secUrl = 'http://quakewatch.freeddns.org:8080/fdsnws/event/1/query';

  Future<List<Earthquake>> fetchEarthquakes(
    String provider,
    double minMagnitude,
    double radius,
    double? latitude,
    double? longitude, {
    String? timeWindow,
  }) async {
    final futures = <Future<List<Earthquake>>>[];

    if (provider == 'both' || provider == 'all' || provider == 'usgs') {
      futures.add(_fetchFromSource(
        url: _usgsUrl,
        providerName: 'USGS',
        minMagnitude: minMagnitude,
        radius: radius,
        latitude: latitude,
        longitude: longitude,
        timeWindow: timeWindow,
        sourceType: 'usgs',
      ));
    }

    if (provider == 'both' || provider == 'all' || provider == 'emsc') {
      futures.add(_fetchFromSource(
        url: _emscUrl,
        providerName: 'EMSC',
        minMagnitude: minMagnitude,
        radius: radius,
        latitude: latitude,
        longitude: longitude,
        timeWindow: timeWindow,
        sourceType: 'emsc',
      ));
    }

    if (provider == 'all' || provider == 'sec') {
      futures.add(_fetchFromSource(
        url: _secUrl,
        providerName: 'SEC',
        minMagnitude: minMagnitude,
        radius: radius,
        latitude: latitude,
        longitude: longitude,
        timeWindow: timeWindow,
        sourceType: 'sec',
      ));
    }

    final results = await Future.wait(futures);
    final allEarthquakes = results.expand((element) => element);
    return allEarthquakes.toSet().toList();
  }

  Future<List<Earthquake>> _fetchFromSource({
    required String url,
    required String providerName,
    required double minMagnitude,
    required double radius,
    required double? latitude,
    required double? longitude,
    required String sourceType,
    String? timeWindow,
  }) async {
    try {
      final queryParameters = {
        'format': 'json',
        'minmagnitude': minMagnitude.toString(),
        'limit': '100',
        'orderby': 'time',
      };

      if (sourceType == 'usgs') {
        queryParameters['format'] = 'geojson';
      }

      if (timeWindow != null) {
        final duration = _parseTimeWindow(timeWindow);
        queryParameters['starttime'] = DateTime.now().subtract(duration).toIso8601String();
        queryParameters['endtime'] = DateTime.now().toIso8601String();
      }

      if (radius > 0 && latitude != null && longitude != null) {
        queryParameters['latitude'] = latitude.toString();
        queryParameters['longitude'] = longitude.toString();
        if (sourceType == 'usgs') {
          queryParameters['maxradiuskm'] = radius.toString();
        } else {
          queryParameters['maxradius'] = (radius / 111.2).toString(); // Convert km to degrees
        }
      }

      final response = await _dio.get(url, queryParameters: queryParameters);

      if (response.statusCode == 200) {
        if (sourceType == 'sec') {
          final events = response.data['seiscomp']?['events'] as List<dynamic>?;
          if (events == null) return [];
          return events.map((json) => Earthquake.fromSecJson(json)).toList();
        } else {
          final features = response.data['features'] as List<dynamic>?;
          if (features == null) return [];
          return features
              .map((json) => sourceType == 'usgs' 
                  ? Earthquake.fromUsgsJson(json) 
                  : Earthquake.fromEmscJson(json))
              .toList();
        }
      } else {
        throw ApiException('Failed to load $providerName earthquakes', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      debugPrint('Error fetching from $providerName (DioException): ${_handleDioError(e)}');
      return [];
    } catch (e) {
      debugPrint('Error fetching from $providerName (UnknownApiException): $e');
      return [];
    }
  }

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
        return const Duration(days: 1);
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
}

