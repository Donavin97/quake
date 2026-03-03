/// Application configuration for API endpoints and services
class AppConfig {
  /// Waveform backend configuration
  /// Use Python Cloud Function with Obspy for better waveform visualization
  static const WaveformBackend waveformBackend = WaveformBackend.pythonCloudFunction;
  
  /// Python Cloud Function URL
  /// Format: https://REGION-PROJECT_ID.cloudfunctions.net/waveform-processor
  static const String pythonCloudFunctionUrl = 'https://us-central1-quakewatch-89047796-c7f3c.cloudfunctions.net/waveform-processor';
  
  /// Whether to fall back to direct IRIS if Python backend fails
  static const bool fallbackToIris = true;
}

/// Available waveform backend options
enum WaveformBackend {
  /// Use Python Cloud Function with Obspy
  pythonCloudFunction,
  
  /// Direct IRIS API calls (existing implementation)
  directIris,
}