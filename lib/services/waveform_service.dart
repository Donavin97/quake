import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/earthquake.dart';
import '../config/app_config.dart';

/// Service to fetch seismic waveform data for earthquakes
/// Uses Python Cloud Function (with Obspy) for waveform processing
class WaveformService {
  static const int sampleRate = 20;
  static const int durationSeconds = 60;
  
  final Dio _dio;

  WaveformService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// Fetch waveform data using the Python Cloud Function backend
  /// Falls back to mock data if Python backend fails
  Future<WaveformResult> getWaveformData(
    Earthquake earthquake, {
    void Function(String)? onProgressUpdate,
  }) async {
    // Try Python Cloud Function backend
    if (AppConfig.waveformBackend == WaveformBackend.pythonCloudFunction) {
      onProgressUpdate?.call('Using Python backend with Obspy...');
      try {
        final result = await _fetchFromPythonBackend(earthquake, onProgressUpdate: onProgressUpdate);
        if (result.imageData != null || result.isMockData) {
          return result;
        }
        // Empty but not error - use mock fallback
        return _fetchMockData(earthquake, onProgressUpdate: onProgressUpdate);
      } catch (e) {
        onProgressUpdate?.call('Python backend error: $e');
        // Return mock data on error
        return _fetchMockData(earthquake, onProgressUpdate: onProgressUpdate);
      }
    }
    
    // Default: use mock data
    return _fetchMockData(earthquake, onProgressUpdate: onProgressUpdate);
  }

  /// Fetch waveform data from Python Cloud Function (Obspy backend with Matplotlib plot)
  Future<WaveformResult> _fetchFromPythonBackend(
    Earthquake earthquake, {
    void Function(String)? onProgressUpdate,
  }) async {
    const url = AppConfig.pythonCloudFunctionUrl;
    if (url.isEmpty) {
      throw Exception('Python Cloud Function URL not configured');
    }

    onProgressUpdate?.call('Querying Python Cloud Function at $url');
    
    final requestBody = {
      'earthquake': {
        'id': earthquake.id,
        'magnitude': earthquake.magnitude,
        'latitude': earthquake.latitude,
        'longitude': earthquake.longitude,
        'time': earthquake.time.toUtc().toIso8601String(),
        'place': earthquake.place,
      },
      'options': {
        'apply_filter': true,
        'filter_type': 'bandpass',
        'freqmin': 0.5,
        'freqmax': 10.0,
      },
    };

    final response = await _dio.post(
      url,
      data: requestBody,
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      
      // Parse base64 image from Python response
      final imageBase64 = data['image'] as String?;
      Uint8List? imageData;
      
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        try {
          imageData = base64Decode(imageBase64);
          onProgressUpdate?.call('Received waveform plot from Python backend');
        } catch (e) {
          onProgressUpdate?.call('Failed to decode image: $e');
        }
      }

      // Parse station info from Python response
      StationInfo? stationInfo;
      final stationData = data['station'] as Map<String, dynamic>?;
      if (stationData != null) {
        stationInfo = StationInfo(
          network: stationData['network'] as String? ?? '',
          station: stationData['station'] as String? ?? '',
          latitude: (stationData['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (stationData['longitude'] as num?)?.toDouble() ?? 0.0,
          elevation: (stationData['elevation'] as num?)?.toDouble() ?? 0.0,
          distanceKm: (stationData['distance_km'] as num?)?.toDouble() ?? 0.0,
          channel: stationData['channel'] as String?,
          locationCode: stationData['location'] as String?,
          sampleRate: (stationData['sample_rate'] as num?)?.toInt(),
        );
        onProgressUpdate?.call('Station: ${stationInfo.displayName} at ${stationInfo.distanceKm.toStringAsFixed(1)} km');
      }

      final isMock = data['is_mock_data'] as bool? ?? false;
      if (isMock) {
        onProgressUpdate?.call('Using simulated waveform data');
      }

      // Parse base64 audio from Python response
      final audioBase64 = data['audio'] as String?;
      Uint8List? audioData;
      
      if (audioBase64 != null && audioBase64.isNotEmpty) {
        try {
          audioData = base64Decode(audioBase64);
          onProgressUpdate?.call('Received audio data from Python backend');
        } catch (e) {
          onProgressUpdate?.call('Failed to decode audio: $e');
        }
      }

      return WaveformResult(
        imageData: imageData,
        audioData: audioData,
        station: stationInfo,
        isMockData: isMock,
        errorMessage: data['error_message'] as String?,
      );
    }

    throw Exception('Python backend returned status ${response.statusCode}');
  }

  /// Fallback: Generate mock waveform data when Python backend fails
  Future<WaveformResult> _fetchMockData(
    Earthquake earthquake, {
    void Function(String)? onProgressUpdate,
  }) async {
    onProgressUpdate?.call('Using simulated waveform data');
    return WaveformResult(
      samples: _generateMockWaveform(earthquake)
    );
  }

  /// Generate mock waveform data based on earthquake properties
  List<WaveformSample> _generateMockWaveform(Earthquake earthquake) {
    final random = Random(earthquake.id.hashCode);
    final samples = <WaveformSample>[];
    
    // Wave characteristics based on magnitude
    final magnitude = earthquake.magnitude;
    final baseAmplitude = magnitude * 0.3;
    final frequency = 1.0 + random.nextDouble() * 2;
    
    // P-wave and S-wave arrival times
    final pWaveArrival = 2.0 + random.nextDouble() * 3;
    final sWaveArrival = pWaveArrival + 3.0 + random.nextDouble() * 5;
    
    for (int i = 0; i < sampleRate * durationSeconds; i++) {
      final time = i / sampleRate;
      double amplitude = 0;
      
      // Background noise
      amplitude += (random.nextDouble() - 0.5) * 0.05;
      
      // P-wave
      if (time >= pWaveArrival) {
        final pProgress = time - pWaveArrival;
        final pEnvelope = _getEnvelope(pProgress, 10);
        amplitude += sin(2 * pi * frequency * time) * baseAmplitude * 0.3 * pEnvelope;
      }
      
      // S-wave
      if (time >= sWaveArrival) {
        final sProgress = time - sWaveArrival;
        final sEnvelope = _getEnvelope(sProgress, 20);
        amplitude += sin(2 * pi * frequency * 0.8 * time) * baseAmplitude * sEnvelope;
      }
      
      // Surface waves
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
  final double time;
  final double amplitude;

  const WaveformSample({required this.time, required this.amplitude});
}

/// Information about a seismic station
class StationInfo {
  final String network;
  final String station;
  final double latitude;
  final double longitude;
  final double elevation;
  final String siteName;
  final double distanceKm;
  final String? channel;
  final String? locationCode;
  final int? sampleRate;

  const StationInfo({
    required this.network,
    required this.station,
    required this.latitude,
    required this.longitude,
    this.elevation = 0,
    this.siteName = '',
    required this.distanceKm,
    this.channel,
    this.locationCode,
    this.sampleRate,
  });

  String get displayName => '$network.$station';

  String get locationString {
    final parts = <String>[];
    if (siteName.isNotEmpty) parts.add(siteName);
    if (elevation != 0) parts.add('${elevation.toInt()}m');
    return parts.join(' • ');
  }

  String get fullChannelId {
    if (locationCode != null && channel != null) {
      return '$locationCode.$channel';
    }
    return channel ?? 'N/A';
  }
}

/// Result containing waveform data and metadata
class WaveformResult {
  final List<WaveformSample> samples;
  final Uint8List? imageData;
  final Uint8List? audioData;
  final StationInfo? station;
  final bool isMockData;
  final String? errorMessage;

  const WaveformResult({
    this.samples = const [],
    this.imageData,
    this.audioData,
    this.station,
    this.isMockData = false,
    this.errorMessage,
  });

  bool get hasImage => imageData != null && imageData!.isNotEmpty;
  bool get hasAudio => audioData != null && audioData!.isNotEmpty;
}
