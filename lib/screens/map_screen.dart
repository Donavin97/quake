
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/earthquake_provider.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final earthquakeProvider = Provider.of<EarthquakeProvider>(context);
    final earthquakes = earthquakeProvider.earthquakes;

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(38.62, -122.71), // Default center
        initialZoom: 5.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.quaketrack',
        ),
        CircleLayer(
          circles: earthquakes.map((earthquake) {
            return CircleMarker(
              point: LatLng(earthquake.latitude, earthquake.longitude),
              radius: earthquake.magnitude * 2,
              color: _getColorForMagnitude(earthquake.magnitude),
              useRadiusInMeter: false,
            );
          }).toList(),
        ),
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: "© OpenStreetMap contributors",
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ],
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'));
              },
          ),
        )
      ],
    );
  }

  Color _getColorForMagnitude(double magnitude) {
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
}
