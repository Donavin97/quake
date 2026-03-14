import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/earthquake.dart';
import '../config/app_config.dart';

/// Service to fetch seismic waveform data for earthquakes
/// Uses Python Cloud Function (with Obspy) for waveform processing
class WaveformService {
  static const int sampleRate = 20;
  static const int durationSeconds = 60;
  
  final Dio _dio;
  
  /// Cache manager for waveform data
  static final CacheManager _waveformCache = CacheManager(
    Config(
      'waveform_cache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  );

  WaveformService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// Fetch waveform data using the Python Cloud Function backend with caching
  Future<WaveformResult> getWaveformData(
    Earthquake earthquake, {
    void Function(String)? onProgressUpdate,
  }) async {
    // 1. Check Cache first
    try {
      final cacheKey = 'waveform_${earthquake.id}';
      final fileInfo = await _waveformCache.getFileFromCache(cacheKey);
      
      if (fileInfo != null) {
        onProgressUpdate?.call('Loading waveform from local cache...');
        final bytes = await fileInfo.file.readAsBytes();
        final json = jsonDecode(utf8.decode(bytes));
        return WaveformResult.fromJson(json);
      }
    } catch (e) {
      onProgressUpdate?.call('Cache read error: $e');
    }

    // 2. Fetch from Python backend if not in cache
    if (AppConfig.waveformBackend == WaveformBackend.pythonCloudFunction) {
      onProgressUpdate?.call('Using Python backend with Obspy...');
      try {
        final result = await _fetchFromPythonBackend(earthquake, onProgressUpdate: onProgressUpdate);
        
        // Save to cache if successful and not mock
        if ((result.hasImage || result.hasAudio) && !result.isMockData) {
          _saveToCache(earthquake.id, result);
        }
        
        if (result.imageData != null || result.isMockData) {
          return result;
        }
        return _fetchMockData(earthquake, onProgressUpdate: onProgressUpdate);
      } catch (e) {
        onProgressUpdate?.call('Python backend error: $e');
        return _fetchMockData(earthquake, onProgressUpdate: onProgressUpdate);
      }
    }
    
    return _fetchMockData(earthquake, onProgressUpdate: onProgressUpdate);
  }

  Future<void> _saveToCache(String earthquakeId, WaveformResult result) async {
    try {
      final cacheKey = 'waveform_$earthquakeId';
      final json = jsonEncode(result.toJson());
      final bytes = utf8.encode(json);
      await _waveformCache.putFile(
        cacheKey,
        Uint8List.fromList(bytes),
        fileExtension: 'json',
      );
    } catch (e) {
      // Ignore cache write errors
    }
  }

  /// Fetch waveform data from Python Cloud Function
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

  Future<WaveformResult> _fetchMockData(
    Earthquake earthquake, {
    void Function(String)? onProgressUpdate,
  }) async {
    onProgressUpdate?.call('Using simulated waveform data');
    return WaveformResult(
      samples: _generateMockWaveform(earthquake)
    );
  }

  List<WaveformSample> _generateMockWaveform(Earthquake earthquake) {
    final random = Random(earthquake.id.hashCode);
    final samples = <WaveformSample>[];
    
    final magnitude = earthquake.magnitude;
    final baseAmplitude = magnitude * 0.3;
    final frequency = 1.0 + random.nextDouble() * 2;
    
    final pWaveArrival = 2.0 + random.nextDouble() * 3;
    final sWaveArrival = pWaveArrival + 3.0 + random.nextDouble() * 5;
    
    for (int i = 0; i < sampleRate * durationSeconds; i++) {
      final time = i / sampleRate;
      double amplitude = 0;
      amplitude += (random.nextDouble() - 0.5) * 0.05;
      
      if (time >= pWaveArrival) {
        final pProgress = time - pWaveArrival;
        final pEnvelope = _getEnvelope(pProgress, 10);
        amplitude += sin(2 * pi * frequency * time) * baseAmplitude * 0.3 * pEnvelope;
      }
      if (time >= sWaveArrival) {
        final sProgress = time - sWaveArrival;
        final sEnvelope = _getEnvelope(sProgress, 20);
        amplitude += sin(2 * pi * frequency * 0.8 * time) * baseAmplitude * sEnvelope;
      }
      if (time >= sWaveArrival + 5) {
        final surfaceProgress = time - sWaveArrival - 5;
        final surfaceEnvelope = _getEnvelope(surfaceProgress, 30);
        amplitude += sin(2 * pi * frequency * 0.5 * time) * baseAmplitude * 0.5 * surfaceEnvelope;
      }
      samples.add(WaveformSample(time: time, amplitude: amplitude));
    }
    return samples;
  }

  double _getEnvelope(double time, double decayTime) {
    if (time <= 0) return 0;
    if (time > decayTime) return exp(-(time - decayTime) / 10);
    return 1 - exp(-time / 2);
  }
}

class WaveformSample {
  final double time;
  final double amplitude;
  const WaveformSample({required this.time, required this.amplitude});

  Map<String, dynamic> toJson() => {'t': time, 'a': amplitude};
  factory WaveformSample.fromJson(Map<String, dynamic> json) => WaveformSample(time: json['t'], amplitude: json['a']);
}

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
  String get fullChannelId => locationCode != null && channel != null ? '$locationCode.$channel' : channel ?? 'N/A';

  Map<String, dynamic> toJson() => {
    'net': network, 'sta': station, 'lat': latitude, 'lon': longitude,
    'ele': elevation, 'site': siteName, 'dist': distanceKm, 'chan': channel,
    'loc': locationCode, 'sr': sampleRate,
  };

  factory StationInfo.fromJson(Map<String, dynamic> json) => StationInfo(
    network: json['net'], station: json['sta'], latitude: json['lat'], longitude: json['lon'],
    elevation: json['ele'], siteName: json['site'], distanceKm: json['dist'],
    channel: json['chan'], locationCode: json['loc'], sampleRate: json['sr'],
  );
}

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

  Map<String, dynamic> toJson() => {
    'samples': samples.map((s) => s.toJson()).toList(),
    'image': imageData != null ? base64Encode(imageData!) : null,
    'audio': audioData != null ? base64Encode(audioData!) : null,
    'station': station?.toJson(),
    'isMock': isMockData,
    'error': errorMessage,
  };

  factory WaveformResult.fromJson(Map<String, dynamic> json) => WaveformResult(
    samples: (json['samples'] as List?)?.map((s) => WaveformSample.fromJson(s)).toList() ?? [],
    imageData: json['image'] != null ? base64Decode(json['image']) : null,
    audioData: json['audio'] != null ? base64Decode(json['audio']) : null,
    station: json['station'] != null ? StationInfo.fromJson(json['station']) : null,
    isMockData: json['isMock'] ?? false,
    errorMessage: json['error'],
  );
}
