import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

    return FlutterMap(
      options: MapOptions(
        initialCenter: currentPosition != null
            ? LatLng(currentPosition.latitude, currentPosition.longitude)
            : const LatLng(0, 0), // Default center
        initialZoom: 2,
        minZoom: 1,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.liebgott.quaketrack',
        ),
        MarkerLayer(
          markers: earthquakes.map((earthquake) {
            final magnitude =
                earthquake.magnitude < 0 ? 0 : earthquake.magnitude;
            return Marker(
              width: magnitude * 4,
              height: magnitude * 4,
              point: LatLng(earthquake.latitude, earthquake.longitude),
              child: GestureDetector(
                onTap: () {
                  context.go('/details', extra: earthquake);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _getColorForMagnitude(magnitude.toDouble()),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        RichText(
          text: TextSpan(
            text: "© OpenStreetMap contributors",
            style: const TextStyle(
                color: Colors.blue, decoration: TextDecoration.underline),
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
