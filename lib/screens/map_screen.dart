
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/earthquake.dart';
import '../providers/earthquake_provider.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final earthquakeProvider = Provider.of<EarthquakeProvider>(context);
    final earthquakes = earthquakeProvider.earthquakes;

    return FlutterMap(
      options: MapOptions(
        center: LatLng(38.62, -122.71), // Default center
        zoom: 5.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        CircleLayer(
          circles: earthquakes.map((earthquake) {
            return CircleMarker(
              point: LatLng(earthquake.latitude, earthquake.longitude),
              radius: earthquake.magnitude * 1000,
              color: _getColorForMagnitude(earthquake.magnitude),
              useRadiusInMeter: true,
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getColorForMagnitude(double magnitude) {
    if (magnitude < 3.0) {
      return Colors.green.withOpacity(0.7);
    } else if (magnitude < 5.0) {
      return Colors.yellow.withOpacity(0.7);
    } else if (magnitude < 7.0) {
      return Colors.orange.withOpacity(0.7);
    } else {
      return Colors.red.withOpacity(0.7);
    }
  }
}
