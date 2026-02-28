import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/earthquake.dart';

/// Service to fetch seismic waveform data for earthquakes
/// Uses IRIS FDSNWS APIs for real seismic data
class WaveformService {
  static const int sampleRate = 20; // samples per second
  static const int durationSeconds = 60; // seconds of waveform to show
  static const int maxRetries = 2;
  static const Duration timeout = Duration(seconds: 15);
  
  final Dio _dio;
  
  // IRIS API endpoints
  static const _stationApiUrl = 'https://service.iris.edu/fdsnws/station/1/query';
  static const _dataselectApiUrl = 'https://service.iris.edu/fdsnws/dataselect/1/query';

  WaveformService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    connectTimeout: timeout,
    receiveTimeout: timeout,
  ));

  /// Fetch waveform data for an earthquake
  /// First finds the closest station, then fetches waveform data
  Future<WaveformResult> getWaveformData(Earthquake earthquake) async {
    try {
      // Find closest station to the earthquake
      final stationInfo = await _findClosestStation(
        earthquake.latitude,
        earthquake.longitude,
        earthquake.time,
      );
      
      if (stationInfo == null) {
        // Fall back to mock data if no station found
        return WaveformResult(
          samples: _generateMockWaveform(earthquake),
          station: null,
          isMockData: true,
          errorMessage: 'No nearby stations found, using simulated data',
        );
      }

      // Fetch waveform data from the station
      final (samples, channel) = await _fetchWaveformData(
        station: stationInfo,
        earthquakeTime: earthquake.time,
      );

      // Update station with channel info
      final stationWithChannel = channel != null
          ? StationInfo(
              network: stationInfo.network,
              station: stationInfo.station,
              latitude: stationInfo.latitude,
              longitude: stationInfo.longitude,
              elevation: stationInfo.elevation,
              siteName: stationInfo.siteName,
              distanceKm: stationInfo.distanceKm,
              channel: channel,
            )
          : stationInfo;

      if (samples.isEmpty) {
        // No waveform data available, use mock
        return WaveformResult(
          samples: _generateMockWaveform(earthquake),
          station: stationWithChannel,
          isMockData: true,
          errorMessage: 'No waveform data available for this station/time, using simulated data',
        );
      }

      return WaveformResult(
        samples: samples,
        station: stationWithChannel,
        isMockData: false,
      );
    } on DioException catch (e) {
      final errorMsg = _handleDioError(e);
      return WaveformResult(
        samples: _generateMockWaveform(earthquake),
        station: null,
        isMockData: true,
        errorMessage: errorMsg,
      );
    } catch (e) {
      return WaveformResult(
        samples: _generateMockWaveform(earthquake),
        station: null,
        isMockData: true,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  /// Handle Dio errors and return user-friendly messages
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return 'No data available for this location/time.';
        } else if (statusCode == 429) {
          return 'Too many requests. Please try again later.';
        } else if (statusCode != null && statusCode >= 500) {
          return 'Server error ($statusCode). Please try again later.';
        }
        return 'Server returned error: $statusCode';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'Network error: ${e.message}';
    }
  }

  /// Find the closest station to a given location using IRIS Station API
  Future<StationInfo?> _findClosestStation(
    double latitude,
    double longitude,
    DateTime time,
  ) async {
    try {
      // Query stations within 500km radius
      final response = await _dio.get(
        _stationApiUrl,
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'minradius': '0',
          'maxradius': '5', // degrees ~500km
          'starttime': _formatDateTime(time.subtract(const Duration(days: 1))),
          'endtime': _formatDateTime(time.add(const Duration(days: 1))),
          'level': 'station',
          'format': 'text',
          'nodata': '404',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final lines = (response.data as String).trim().split('\n');
        if (lines.length > 1) {
          // Skip header line, parse first data line
          return _parseStationLine(lines[1], latitude, longitude);
        }
      }
      return null;
    } on DioException {
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse a station line from IRIS text format
  /// Format: Network|Station|Latitude|Longitude|Elevation|Site|StartTime|EndTime
  StationInfo? _parseStationLine(String line, double eqLat, double eqLon) {
    final parts = line.split('|');
    if (parts.length >= 6) {
      final stationLat = double.tryParse(parts[2]);
      final stationLon = double.tryParse(parts[3]);
      final elevation = double.tryParse(parts[4]) ?? 0;
      final siteName = parts.length > 5 ? parts[5] : '';
      
      if (stationLat != null && stationLon != null) {
        final distance = _calculateDistance(eqLat, eqLon, stationLat, stationLon);
        return StationInfo(
          network: parts[0],
          station: parts[1],
          latitude: stationLat,
          longitude: stationLon,
          elevation: elevation,
          siteName: siteName,
          distanceKm: distance,
        );
      }
    }
    return null;
  }

  /// Calculate great circle distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  /// Preferred channels in order of priority
  /// BH = Broad Band (20 or 40 SPS), HH = High Broad Band (100 SPS), SH = Short Period (1 SPS)
  static const _preferredChannels = ['BHZ', 'HHZ', 'SHZ'];

  /// Fetch waveform data from IRIS Dataselect API
  /// Tries multiple channel types in order of preference
  /// Returns a tuple of (samples, channelUsed) or ([], null) if no data
  Future<(List<WaveformSample>, String?)> _fetchWaveformData({
    required StationInfo station,
    required DateTime earthquakeTime,
  }) async {
    // Calculate time window: 30 seconds before to 30 seconds after event time
    final startTime = earthquakeTime.subtract(const Duration(seconds: 30));
    final endTime = earthquakeTime.add(const Duration(seconds: 30));
    
    // Try each channel type in order of preference
    for (final channel in _preferredChannels) {
      final samples = await _fetchWaveformForChannel(
        station: station,
        channel: channel,
        startTime: startTime,
        endTime: endTime,
      );
      
      if (samples.isNotEmpty) {
        return (samples, channel);
      }
    }
    
    final List<WaveformSample> emptySamples = [];
    return (emptySamples, null);
  }
  
  /// Fetch waveform data for a specific channel with retry logic
  Future<List<WaveformSample>> _fetchWaveformForChannel({
    required StationInfo station,
    required String channel,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.get(
          _dataselectApiUrl,
          queryParameters: {
            'network': station.network,
            'station': station.station,
            'location': '00',
            'channel': channel,
            'starttime': _formatDateTime(startTime),
            'endtime': _formatDateTime(endTime),
          },
          options: Options(
            responseType: ResponseType.bytes,
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          return _parseMiniSeed(Uint8List.fromList(response.data));
        }
        return [];
      } on DioException catch (e) {
        // Don't retry on client errors (4xx except 429)
        final statusCode = e.response?.statusCode;
        if (statusCode != null && statusCode >= 400 && statusCode < 500 && statusCode != 429) {
          return [];
        }
        // Wait before retrying
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      } catch (e) {
        break;
      }
    }
    
    return [];
  }

  /// Parse miniSEED data to extract waveform samples
  List<WaveformSample> _parseMiniSeed(Uint8List data) {
    final samples = <WaveformSample>[];
    
    if (data.length < 512) return samples;

    try {
      int offset = 0;
      double currentTime = 0;
      int sampleRate = 0;
      int currentSampleIndex = 0;
      
      while (offset + 512 <= data.length) {
        final header = data.sublist(offset, offset + 512);
        
        // Check for valid miniSEED header
        final qualityIndicator = String.fromCharCodes(header.sublist(6, 8));
        if (qualityIndicator != 'LQ' && qualityIndicator != 'DR' && qualityIndicator != 'RD') {
          offset += 512;
          continue;
        }

        // Get sample rate from bytes 18-19
        final sampleRateFactor = (header[18] << 8) | header[19];
        if (sampleRateFactor > 0) {
          sampleRate = sampleRateFactor;
        } else if (sampleRateFactor < 0) {
          sampleRate = (1 / sampleRateFactor.abs()).round();
        }

        // Get number of samples from bytes 44-45
        final numSamples = (header[44] << 8) | header[45];
        
        // Get first sample value (for STEIM2 decompression) from bytes 46-49
        final firstSample = (header[46] & 0xFF) |
            ((header[47] & 0xFF) << 8) |
            ((header[48] & 0xFF) << 16) |
            ((header[49] & 0xFF) << 24);
        // Sign extend 32-bit value
        int firstSampleSigned;
        if (firstSample & 0x80000000 != 0) {
          firstSampleSigned = firstSample | 0xFFFFFFFF00000000;
        } else {
          firstSampleSigned = firstSample;
        }

        // Get start time from header
        final startTime = _parseMiniSeedTime(header);
        if (currentSampleIndex == 0) {
          currentTime = 0;
        } else {
          currentTime = startTime;
        }

        // Extract data samples (after 512 byte header)
        final dataStart = offset + 512;
        final dataLength = numSamples * 4;
        
        if (dataStart + dataLength <= data.length) {
          final compressedData = data.sublist(dataStart, dataStart + dataLength);
          final decompressed = _decompressSteim2(compressedData, numSamples, initialValue: firstSampleSigned);
          
          final double startTimeSeconds = currentSampleIndex == 0 ? 0 : 
            (startTime - (currentTime - (currentSampleIndex / (sampleRate > 0 ? sampleRate : 20))));
          
          for (int i = 0; i < decompressed.length; i++) {
            final normalizedAmplitude = decompressed[i] / 1000000.0;
            samples.add(WaveformSample(
              time: startTimeSeconds + (i / (sampleRate > 0 ? sampleRate : 20)),
              amplitude: normalizedAmplitude.clamp(-10.0, 10.0),
            ));
          }
          
          currentSampleIndex += numSamples;
        }

        offset += 512;
      }

      if (samples.isEmpty) {
        return [];
      }

      // Normalize time to start from 0
      if (samples.isNotEmpty) {
        final startTime = samples.first.time;
        for (int i = 0; i < samples.length; i++) {
          samples[i] = WaveformSample(
            time: samples[i].time - startTime,
            amplitude: samples[i].amplitude,
          );
        }
      }

      return samples;
    } catch (e) {
      return [];
    }
  }

  /// Parse miniSEED timestamp from header bytes
  double _parseMiniSeedTime(List<int> header) {
    final year = (header[30] << 8) | header[31];
    final dayOfYear = (header[32] << 8) | header[33];
    final hour = header[34];
    final minute = header[35];
    final second = header[36];
    final tenths = header[37];

    if (year < 1900) return 0;

    try {
      final dateTime = DateTime(year, 1, 1).add(Duration(
        days: dayOfYear - 1,
        hours: hour,
        minutes: minute,
        seconds: second,
        milliseconds: tenths * 100,
      ));
      return dateTime.millisecondsSinceEpoch / 1000.0;
    } catch (e) {
      return 0;
    }
  }

  /// Steim2 decompression
  /// Steim2 uses 2-bit control words:
  /// - 00: 4 differences of 7 bits each
  /// - 01: 2 differences of 14 bits each
  /// - 10: 1 difference of 30 bits (full precision)
  /// - 11: 1 sample value (absolute value, not difference)
  List<double> _decompressSteim2(Uint8List compressed, int numSamples, {int? initialValue}) {
    final samples = <double>[];
    
    if (compressed.isEmpty || numSamples <= 0) return samples;

    try {
      // Initialize with first sample or provided initial value
      int prevValue = initialValue ?? 0;
      int sampleCount = 0;
      
      for (int i = 0; i < compressed.length - 3 && sampleCount < numSamples; i += 4) {
        // Each 32-bit word contains 2 control bits + 30 data bits
        final word = (compressed[i] & 0xFF) |
            ((compressed[i + 1] & 0xFF) << 8) |
            ((compressed[i + 2] & 0xFF) << 16) |
            ((compressed[i + 3] & 0xFF) << 24);
        
        final controlBits = (word >> 30) & 0x03;
        final dataBits = word & 0x3FFFFFFF;
        
        // Handle sign extension for 30-bit value
        int diff;
        if (dataBits & 0x20000000 != 0) {
          diff = dataBits | 0xC0000000;
        } else {
          diff = dataBits & 0x3FFFFFFF;
        }
        
        switch (controlBits) {
          case 0x00: // 4 differences of 7 bits each
            for (int j = 0; j < 4 && sampleCount < numSamples; j++) {
              // Extract 7-bit values (little-endian within the 30 bits)
              final bitOffset = j * 7;
              final sevenBitValue = (dataBits >> bitOffset) & 0x7F;
              // Sign extend 7-bit
              int sevenBitSigned;
              if (sevenBitValue & 0x40 != 0) {
                sevenBitSigned = sevenBitValue | 0xFFFFFF80;
              } else {
                sevenBitSigned = sevenBitValue;
              }
              prevValue += sevenBitSigned;
              samples.add(prevValue.toDouble());
              sampleCount++;
            }
            break;
            
          case 0x01: // 2 differences of 14 bits each
            for (int j = 0; j < 2 && sampleCount < numSamples; j++) {
              final bitOffset = j * 14;
              final fourteenBitValue = (dataBits >> bitOffset) & 0x3FFF;
              // Sign extend 14-bit
              int fourteenBitSigned;
              if (fourteenBitValue & 0x2000 != 0) {
                fourteenBitSigned = fourteenBitValue | 0xFFFFC000;
              } else {
                fourteenBitSigned = fourteenBitValue;
              }
              prevValue += fourteenBitSigned;
              samples.add(prevValue.toDouble());
              sampleCount++;
            }
            break;
            
          case 0x02: // 1 difference of 30 bits (full precision)
            prevValue += diff;
            samples.add(prevValue.toDouble());
            sampleCount++;
            break;
            
          case 0x03: // 1 sample value (absolute, not difference)
            prevValue = diff;
            samples.add(prevValue.toDouble());
            sampleCount++;
            break;
        }
      }
      
      // Pad with last value if needed
      while (samples.length < numSamples) {
        samples.add(samples.isNotEmpty ? samples.last : 0);
      }
    } catch (e) {
      // Return empty on error
    }

    return samples;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}T'
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  /// Generate mock waveform data based on earthquake properties
  List<WaveformSample> _generateMockWaveform(Earthquake earthquake) {
    final random = Random(earthquake.id.hashCode);
    final List<WaveformSample> samples = [];
    
    // Wave characteristics based on magnitude
    final magnitude = earthquake.magnitude;
    final baseAmplitude = magnitude * 0.3; // Larger magnitude = larger amplitude
    final frequency = 1.0 + random.nextDouble() * 2; // Random frequency between 1-3 Hz
    
    // P-wave arrival time (approximately at start for simplicity)
    final pWaveArrival = 2.0 + random.nextDouble() * 3;
    final sWaveArrival = pWaveArrival + 3.0 + random.nextDouble() * 5;
    
    for (int i = 0; i < sampleRate * durationSeconds; i++) {
      final time = i / sampleRate;
      double amplitude = 0;
      
      // Background noise (always present)
      amplitude += (random.nextDouble() - 0.5) * 0.05;
      
      // P-wave arrival (primary wave)
      if (time >= pWaveArrival) {
        final pWaveProgress = time - pWaveArrival;
        final pWaveEnvelope = _getEnvelope(pWaveProgress, 10);
        amplitude += sin(2 * pi * frequency * time) * baseAmplitude * 0.3 * pWaveEnvelope;
      }
      
      // S-wave arrival (secondary wave - larger amplitude)
      if (time >= sWaveArrival) {
        final sWaveProgress = time - sWaveArrival;
        final sWaveEnvelope = _getEnvelope(sWaveProgress, 20);
        amplitude += sin(2 * pi * frequency * 0.8 * time) * baseAmplitude * sWaveEnvelope;
      }
      
      // Surface waves (arriving later, longer duration)
      if (time >= sWaveArrival + 5) {
        final surfaceProgress = time - sWaveArrival - 5;
        final surfaceEnvelope = _getEnvelope(surfaceProgress, 30);
        amplitude += sin(2 * pi * frequency * 0.5 * time) * baseAmplitude * 0.5 * surfaceEnvelope;
      }
      
      samples.add(WaveformSample(time: time, amplitude: amplitude));
    }
    
    return samples;
  }

  /// Get envelope function for wave attenuation
  double _getEnvelope(double time, double decayTime) {
    if (time <= 0) return 0;
    if (time > decayTime) return exp(-(time - decayTime) / 10);
    return 1 - exp(-time / 2);
  }
}

/// Represents a single waveform data point
class WaveformSample {
  final double time; // time in seconds
  final double amplitude; // normalized amplitude

  const WaveformSample({required this.time, required this.amplitude});
}

/// Information about a seismic station
class StationInfo {
  final String network;
  final String station;
  final double latitude;
  final double longitude;
  final double elevation; // in meters
  final String siteName;
  final double distanceKm;
  final String? channel; // The channel being used (e.g., BHZ, HHZ)

  const StationInfo({
    required this.network,
    required this.station,
    required this.latitude,
    required this.longitude,
    this.elevation = 0,
    this.siteName = '',
    required this.distanceKm,
    this.channel,
  });

  String get displayName => '$network.$station';

  String get locationString {
    final parts = <String>[];
    if (siteName.isNotEmpty) parts.add(siteName);
    if (elevation != 0) parts.add('${elevation.toInt()}m');
    return parts.join(' • ');
  }
}

/// Result containing waveform data and metadata
class WaveformResult {
  final List<WaveformSample> samples;
  final StationInfo? station;
  final bool isMockData;
  final String? errorMessage;

  const WaveformResult({
    required this.samples,
    this.station,
    this.isMockData = false,
    this.errorMessage,
  });
}
