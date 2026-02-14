import 'dart:convert';

import 'package:flutter/gestures.dart';
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
  List<Marker> _markers = [];
  late EarthquakeProvider _earthquakeProvider;
  List<Polygon> _plates = [];
  List<Polyline> _faults = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _earthquakeProvider = Provider.of<EarthquakeProvider>(context, listen: false);
    _earthquakeProvider.addListener(_updateMarkers);
    _updateMarkers(); // Initial update
    _loadGeoJson();
  }

  @override
  void dispose() {
    _earthquakeProvider.removeListener(_updateMarkers);
    super.dispose();
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
        final coordinates = feature['geometry']['coordinates'] as List;
        final points = coordinates[0].map<latlong.LatLng>((coords) {
          return latlong.LatLng(coords[1], coords[0]);
        }).toList();
        return Polygon(
          points: points,
          color: Colors.red.withAlpha((255 * 0.2).round()),
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
      }).where((p) => p != null).cast<Polyline>().toList();
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
            onTap: () {
              context.go('/details', extra: earthquake);
            },
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
    if (magnitude < 0) return 5;
    if (magnitude < 3.0) return 10;
    if (magnitude < 5.0) return 20;
    if (magnitude < 7.0) return 30;
    return 40;
  }

  Color _getMarkerColorForMagnitude(double magnitude) {
    if (magnitude < 3.0) {
      return Colors.green.withAlpha(179);
    } else if (magnitude < 5.0) {
      return Colors.yellow.withAlpha(179);
    } else if (magnitude < 7.0) {
      return Colors.orange.withAlpha(179);
    } else {
      return Colors.red.withAlpha(179);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final currentPosition = locationProvider.currentPosition;

    latlong.LatLng initialCenter;
    if (currentPosition != null) {
      initialCenter = latlong.LatLng(currentPosition.latitude, currentPosition.longitude);
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 1,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.liebgott.quaketrack',
        ),
        PolygonLayer(polygons: _plates),
        PolylineLayer(polylines: _faults),
        MarkerLayer(
          markers: _markers,
        ),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: '© ',
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: 'OpenStreetMap',
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'));
                  },
              ),
              const TextSpan(
                text: ' contributors',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
