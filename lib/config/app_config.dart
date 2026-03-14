/// Application configuration for API endpoints, ads, and services
class AppConfig {
  // --- Waveform Configuration ---
  /// Use Python Cloud Function with Obspy for better waveform visualization
  static const WaveformBackend waveformBackend = WaveformBackend.pythonCloudFunction;
  
  /// Python Cloud Function URL
  static const String pythonCloudFunctionUrl = 'https://us-central1-quakewatch-89047796-c7f3c.cloudfunctions.net/waveform-processor';
  
  /// Whether to fall back to direct IRIS if Python backend fails
  static const bool fallbackToIris = true;

  // --- API Endpoints ---
  static const String usgsUrl = 'https://earthquake.usgs.gov/fdsnws/event/1/query';
  static const String emscUrl = 'https://www.seismicportal.eu/fdsnws/event/1/query';
  static const String secUrl = 'http://www.quakewatch.freeddns.org:8080/fdsnws/event/1/query';
  static const String nominatimUrl = 'https://nominatim.openstreetmap.org/reverse';
  static const String emscWebSocketUrl = 'wss://www.seismicportal.eu/standing_order/websocket';
  static const String privacyPolicyUrl = 'https://quakewatch-89047796-c7f3c.web.app/privacy.html';
  
  // --- Map Layers ---
  static const String osmHotTileUrl = 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
  static const String usgsPlatesWmsUrl = 'https://earthquake.usgs.gov/arcgis/services/eq/map_plateboundaries/MapServer/WMSServer';

  // --- AdMob Configuration ---
  // Replace these with test IDs during development if needed
  static const String homeBannerAdUnitId = 'ca-app-pub-7112901918437892/4314697520';
  static const String detailInterstitialAdUnitId = 'ca-app-pub-7112901918437892/1244453690';
}

/// Available waveform backend options
enum WaveformBackend {
  /// Use Python Cloud Function with Obspy
  pythonCloudFunction,
  
  /// Direct IRIS API calls
  directIris,
}
