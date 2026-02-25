import 'dart:async'; // Added
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/earthquake_provider.dart';
import '../providers/location_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final EarthquakeProvider _earthquakeProvider;
  late final LocationProvider _locationProvider;
  List<Marker> _markers = [];
  final MapController _mapController = MapController();
  late LatLngBounds _currentVisibleBounds; // To store current visible bounds

  bool _showPlates = true;
  bool _showFaults = true;

  // For debouncing map updates
  Timer? _debounce;
  final Duration _debounceDuration = const Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _earthquakeProvider = context.read<EarthquakeProvider>();
    _locationProvider = context.read<LocationProvider>();

    _earthquakeProvider.addListener(_onEarthquakesChanged);
    _locationProvider.addListener(_updateMapCenter);

    // Initialize bounds to a default (world view)
    _currentVisibleBounds = LatLngBounds(
      const LatLng(-90, -180),
      const LatLng(90, 180),
    );
    _filterAndDisplayMarkers(); // Initial marker display

    // No need to call _updateMarkers directly anymore as it will be triggered by _filterAndDisplayMarkers
  }

  @override
  void dispose() {
    _earthquakeProvider.removeListener(_onEarthquakesChanged);
    _locationProvider.removeListener(_updateMapCenter);
    _debounce?.cancel(); // Cancel debounce timer
    super.dispose();
  }

  void _updateMapCenter() {
    final currentPosition = _locationProvider.currentPosition;
    if (currentPosition != null && _mapController.camera.center.latitude == 0) {
      _mapController.move(
        LatLng(currentPosition.latitude, currentPosition.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  void _zoomInToUserLocation() {
    final currentPosition = _locationProvider.currentPosition;
    if (currentPosition != null) {
      _mapController.move(
        LatLng(currentPosition.latitude, currentPosition.longitude),
        7.0, // Zoom level for country-level detail
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User location not available.')),
      );
    }
  }

  void _zoomOutToGlobalView() {
    _mapController.move(
      LatLng(0.0, 0.0), // Center of the world
      2.0, // Zoom level for global view
    );
  }

  void _onEarthquakesChanged() {
    if (!mounted) return;
    _filterAndDisplayMarkers();
  }

  void _onMapEvent(MapEvent mapEvent) {
    // Update bounds and filter if the map moved (any event, debounce will handle frequency)
    // The previous explicit checks for MapEventMoveEnd/MapEventZoomEnd were causing errors.
    _currentVisibleBounds = _mapController.camera.visibleBounds;
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      _filterAndDisplayMarkers();
    });
  }

  void _filterAndDisplayMarkers() {
    final earthquakes = _earthquakeProvider.earthquakes;
    if (!mounted) return;

    final filteredEarthquakes = earthquakes.where((eq) {
      final point = LatLng(eq.latitude, eq.longitude);
      return _currentVisibleBounds.contains(point);
    }).toList();

    setState(() {
      _markers = filteredEarthquakes.map((earthquake) {
        final magnitude = earthquake.magnitude;
        return Marker(
          width: 40.0,
          height: 40.0,
          point: LatLng(earthquake.latitude, earthquake.longitude),
          child: GestureDetector(
            onTap: () => context.go('/details/${earthquake.id}', extra: earthquake),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: _getMarkerSize(magnitude),
                  height: _getMarkerSize(magnitude),
                  decoration: BoxDecoration(
                    color: _getMarkerColorForMagnitude(magnitude),
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  magnitude.toStringAsFixed(1), // Display magnitude with 1 decimal place
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getMarkerSize(magnitude) / 3, // Scale text size with marker size
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList();
    });
  }

  double _getMarkerSize(double magnitude) {
    if (magnitude < 3.0) return 12;
    if (magnitude < 5.0) return 20;
    if (magnitude < 7.0) return 28;
    return 36;
  }

  Color _getMarkerColorForMagnitude(double magnitude) {
    if (magnitude < 3.0) return Colors.green.withAlpha(180);
    if (magnitude < 5.0) return Colors.yellow.withAlpha(180);
    if (magnitude < 7.0) return Colors.orange.withAlpha(180);
    return Colors.red.withAlpha(180);
  }

  Widget _buildMap(LatLng initialCenter) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 4,
            onMapEvent: _onMapEvent, // Added map event listener
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.liebgott.quaketrack',
            ),
            if (_showPlates)
              TileLayer(
                wmsOptions: WMSTileLayerOptions(
                  baseUrl: 'https://edumaps.esri.ca/ArcGIS/services/MapServices/TectonicPlates/MapServer/WMSServer',
                  layers: ['0'],
                ),
                userAgentPackageName: 'com.liebgott.quaketrack',
              ),
            if (_showFaults)
              TileLayer(
                wmsOptions: WMSTileLayerOptions(
                  baseUrl: 'https://edumaps.esri.ca/ArcGIS/services/MapServices/TectonicPlates/MapServer/WMSServer',
                  layers: ['1'],
                ),
                userAgentPackageName: 'com.liebgott.quaketrack',
              ),
            MarkerLayer(markers: _markers),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                ),
                TextSourceAttribution(
                  'Esri Canada',
                  onTap: () => launchUrl(Uri.parse('http://edumaps.esri.ca')),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'zoomInButton',
                onPressed: _zoomInToUserLocation,
                backgroundColor: Theme.of(context).primaryColor,
                icon: const Icon(Icons.zoom_in),
                label: const Text('Zoom In'),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                heroTag: 'zoomOutButton',
                onPressed: _zoomOutToGlobalView,
                backgroundColor: Theme.of(context).primaryColor,
                icon: const Icon(Icons.zoom_out),
                label: const Text('Zoom Out'),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                heroTag: 'platesToggle',
                onPressed: () => setState(() => _showPlates = !_showPlates),
                backgroundColor: _showPlates ? Colors.red : Colors.white,
                icon: Icon(Icons.public, color: _showPlates ? Colors.white : Colors.red),
                label: Text('Plates', style: TextStyle(color: _showPlates ? Colors.white : Colors.red)),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                heroTag: 'faultsToggle',
                onPressed: () => setState(() => _showFaults = !_showFaults),
                backgroundColor: _showFaults ? Colors.orange : Colors.white,
                icon: Icon(Icons.reorder, color: _showFaults ? Colors.white : Colors.orange),
                label: Text('Faults', style: TextStyle(color: _showFaults ? Colors.white : Colors.orange)),
              ),
            ],
          ),
        ),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 20,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withAlpha(220),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Magnitude',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(Colors.red, '7.0+'),
            _buildLegendItem(Colors.orange, '5.0 - 6.9'),
            _buildLegendItem(Colors.yellow, '3.0 - 4.9'),
            _buildLegendItem(Colors.green, '< 3.0'),
            if (_showPlates || _showFaults) ...[
              const Divider(height: 16),
              if (_showPlates)
                _buildLegendItem(
                  Colors.red.withAlpha(180),
                  'Plate Boundaries',
                  isLine: true,
                ),
              if (_showFaults)
                _buildLegendItem(
                  Colors.orange.withAlpha(150),
                  'Fault Lines',
                  isLine: true,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool isLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: isLine ? 3 : 16,
            decoration: BoxDecoration(
              color: color,
              shape: isLine ? BoxShape.rectangle : BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final currentPosition = locationProvider.currentPosition;
        if (currentPosition != null) {
          return _buildMap(
            LatLng(currentPosition.latitude, currentPosition.longitude),
          );
        } else {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Waiting for location data...'),
                SizedBox(height: 8),
                Text('Please ensure location services are enabled.'),
              ],
            ),
          );
        }
      },
    );
  }
}