import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as latlong;
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
  List<Polyline> _plates = [];
  List<Polyline> _faults = [];
  final MapController _mapController = MapController();

  bool _showPlates = true;
  bool _showFaults = true;
  bool _isGeoJsonLoading = false;

  @override
  void initState() {
    super.initState();
    _earthquakeProvider = context.read<EarthquakeProvider>();
    _locationProvider = context.read<LocationProvider>();
    _earthquakeProvider.addListener(_updateMarkers);
    _locationProvider.addListener(_updateMapCenter);
    _updateMarkers();
    _loadGeoJson();
  }

  @override
  void dispose() {
    _earthquakeProvider.removeListener(_updateMarkers);
    _locationProvider.removeListener(_updateMapCenter);
    super.dispose();
  }

  void _updateMapCenter() {
    final currentPosition = _locationProvider.currentPosition;
    if (currentPosition != null && _mapController.camera.center.latitude == 0) {
      _mapController.move(
        latlong.LatLng(currentPosition.latitude, currentPosition.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  Future<void> _loadGeoJson() async {
    setState(() {
      _isGeoJsonLoading = true;
    });

    try {
      // Load Plates
      final platesString = await rootBundle.loadString('assets/plates.json');
      final platesJson = json.decode(platesString);
      final platesFeatures = platesJson['features'] as List;

      // Load Faults
      final faultsString = await rootBundle.loadString('assets/faults.json');
      final faultsJson = json.decode(faultsString);
      final faultsFeatures = faultsJson['features'] as List;

      if (!mounted) return;

      final List<Polyline> loadedPlates = [];
      for (final feature in platesFeatures) {
        final geometry = feature['geometry'];
        if (geometry['type'] == 'LineString') {
          final coordinates = geometry['coordinates'] as List;
          final points = coordinates.map<latlong.LatLng>((coords) {
            return latlong.LatLng(coords[1].toDouble(), coords[0].toDouble());
          }).toList();
          loadedPlates.add(Polyline(
            points: points,
            color: Colors.red.withAlpha(180),
            strokeWidth: 2.0,
          ));
        }
      }

      final List<Polyline> loadedFaults = [];
      for (final feature in faultsFeatures) {
        final geometry = feature['geometry'];
        if (geometry['type'] == 'LineString') {
          final coordinates = geometry['coordinates'] as List;
          final points = coordinates.map<latlong.LatLng>((coords) {
            return latlong.LatLng(coords[1].toDouble(), coords[0].toDouble());
          }).toList();
          loadedFaults.add(Polyline(
            points: points,
            color: Colors.orange.withAlpha(150),
          ));
        }
      }

      setState(() {
        _plates = loadedPlates;
        _faults = loadedFaults;
        _isGeoJsonLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading geological data: $e');
      if (mounted) {
        setState(() {
          _isGeoJsonLoading = false;
        });
      }
    }
  }

  void _updateMarkers() {
    final earthquakes = _earthquakeProvider.earthquakes;
    if (!mounted) return;
    setState(() {
      _markers = earthquakes.map((earthquake) {
        final magnitude = earthquake.magnitude;
        return Marker(
          width: 40.0,
          height: 40.0,
          point: latlong.LatLng(earthquake.latitude, earthquake.longitude),
          child: GestureDetector(
            onTap: () => context.go('/details/${earthquake.id}', extra: earthquake),
            child: Icon(
              Icons.circle,
              color: _getMarkerColorForMagnitude(magnitude),
              size: _getMarkerSize(magnitude),
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

  Widget _buildMap(latlong.LatLng initialCenter) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 4,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.liebgott.quaketrack',
            ),
            if (_showPlates) PolylineLayer(polylines: _plates),
            if (_showFaults) PolylineLayer(polylines: _faults),
            MarkerLayer(markers: _markers),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'platesToggle',
                onPressed: () => setState(() => _showPlates = !_showPlates),
                backgroundColor: _showPlates ? Colors.red : Colors.white,
                child: Icon(Icons.public, color: _showPlates ? Colors.white : Colors.red),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'faultsToggle',
                onPressed: () => setState(() => _showFaults = !_showFaults),
                backgroundColor: _showFaults ? Colors.orange : Colors.white,
                child: Icon(Icons.reorder, color: _showFaults ? Colors.white : Colors.orange),
              ),
            ],
          ),
        ),
        if (_isGeoJsonLoading)
          const Positioned(
            bottom: 20,
            left: 20,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text('Loading geological data...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final currentPosition = locationProvider.currentPosition;
        if (currentPosition != null) {
          return _buildMap(
            latlong.LatLng(currentPosition.latitude, currentPosition.longitude),
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