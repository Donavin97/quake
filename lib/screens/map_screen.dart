import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/earthquake_provider.dart';
import '../providers/location_provider.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final earthquakeProvider = Provider.of<EarthquakeProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final earthquakes = earthquakeProvider.earthquakes;
    final currentPosition = locationProvider.currentPosition;

    if (currentPosition == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(currentPosition.latitude, currentPosition.longitude),
        initialZoom: 2,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        MarkerLayer(
          markers: earthquakes.map((earthquake) {
            final magnitude = earthquake.magnitude < 0 ? 0 : earthquake.magnitude;
            return Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(earthquake.latitude, earthquake.longitude),
              child: GestureDetector(
                onTap: () {
                  context.go('/details', extra: earthquake);
                },
                child: Icon(
                  Icons.circle,
                  color: _getMarkerColorForMagnitude(magnitude.toDouble()),
                  size: magnitude.toDouble() * 5,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getMarkerColorForMagnitude(double magnitude) {
    if (magnitude < 3.0) {
      return Colors.green;
    } else if (magnitude < 5.0) {
      return Colors.yellow;
    } else if (magnitude < 7.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
