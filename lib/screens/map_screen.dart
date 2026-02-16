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
  List<Polygon> _plates = [];
  List<Polyline> _faults = [];
  final MapController _mapController = MapController();

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
    if (currentPosition != null) {
      _mapController.move(
        latlong.LatLng(currentPosition.latitude, currentPosition.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  Future<void> _loadGeoJson() async {
    final platesString = await rootBundle.loadString('assets/plates.json');
    final platesJson = json.decode(platesString);
    final platesFeatures = platesJson['features'] as List;

    final faultsString = await rootBundle.loadString('assets/faults.json');
    final faultsJson = json.decode(faultsString);
    final faultsFeatures = faultsJson['features'] as List;

    if (!mounted) return;

    setState(() {
      _plates = platesFeatures.map((feature) {
        final coordinates = feature['geometry']['coordinates'][0] as List;
        final points = coordinates.map<latlong.LatLng>((coords) {
          return latlong.LatLng(coords[1], coords[0]);
        }).toList();
        return Polygon(
          points: points,
          color: const Color.fromRGBO(255, 0, 0, 0.2),
          borderColor: Colors.red,
          borderStrokeWidth: 1,
        );
      }).toList();

      _faults = faultsFeatures.map((feature) {
        final geometry = feature['geometry'];
        if (geometry['type'] == 'LineString') {
          final coordinates = geometry['coordinates'] as List;
          final points = coordinates.map<latlong.LatLng>((coords) {
            return latlong.LatLng(coords[1], coords[0]);
          }).toList();
          return Polyline(
            points: points,
            color: Colors.orange,
          );
        }
        return null;
      }).whereType<Polyline>().toList();
    });
  }

  void _updateMarkers() {
    final earthquakes = _earthquakeProvider.earthquakes;
    if (!mounted) return;
    setState(() {
      _markers = earthquakes.map((earthquake) {
        final magnitude = earthquake.magnitude;
        return Marker(
          width: 80.0,
          height: 80.0,
          point: latlong.LatLng(earthquake.latitude, earthquake.longitude),
          child: GestureDetector(
            onTap: () => context.go('/details/${earthquake.id}', extra: earthquake),
            child: Tooltip(
              message: 'Magnitude: ${earthquake.magnitude}',
              child: Icon(
                Icons.circle,
                color: _getMarkerColorForMagnitude(magnitude),
                size: _getMarkerSize(magnitude),
              ),
            ),
          ),
        );
      }).toList();
    });
  }

  double _getMarkerSize(double magnitude) {
    if (magnitude < 3.0) return 10;
    if (magnitude < 5.0) return 20;
    if (magnitude < 7.0) return 30;
    return 40;
  }

  Color _getMarkerColorForMagnitude(double magnitude) {
    if (magnitude < 3.0) return const Color.fromRGBO(76, 175, 80, 0.7);
    if (magnitude < 5.0) return const Color.fromRGBO(255, 235, 59, 0.7);
    if (magnitude < 7.0) return const Color.fromRGBO(255, 152, 0, 0.7);
    return const Color.fromRGBO(244, 67, 54, 0.7);
  }

  Widget _buildMap(latlong.LatLng initialCenter) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.liebgott.quaketrack',
        ),
        PolygonLayer(polygons: _plates),
        PolylineLayer(polylines: _faults),
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