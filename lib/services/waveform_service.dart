import 'dart:async';
import 'dart:math';
import '../models/earthquake.dart';

/// Service to fetch seismic waveform data for earthquakes
/// Currently uses mock data - can be extended to use IRIS API
class WaveformService {
  static const int sampleRate = 20; // samples per second
  static const int durationSeconds = 60; // seconds of waveform to show

  /// Fetch waveform data for an earthquake
  /// Returns list of (timeInSeconds, amplitude) pairs
  Future<List<WaveformSample>> getWaveformData(Earthquake earthquake) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Generate mock seismic waveform data
    // In production, this would call IRIS or other seismic data API
    return _generateMockWaveform(earthquake);
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
