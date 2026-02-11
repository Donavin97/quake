import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
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

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(currentPosition.latitude, currentPosition.longitude),
        zoom: 2,
      ),
      markers: earthquakes.map((earthquake) {
        final magnitude = earthquake.magnitude < 0 ? 0 : earthquake.magnitude;
        return Marker(
          markerId: MarkerId(earthquake.id),
          position: LatLng(earthquake.latitude, earthquake.longitude),
          infoWindow: InfoWindow(
            title: earthquake.place,
            snippet: 'Magnitude: ${earthquake.magnitude.toStringAsFixed(2)}',
          ),
          icon: _getMarkerIconForMagnitude(magnitude.toDouble()),
          onTap: () {
            context.go('/details', extra: earthquake);
          },
        );
      }).toSet(),
    );
  }

  BitmapDescriptor _getMarkerIconForMagnitude(double magnitude) {
    double hue;
    if (magnitude < 3.0) {
      hue = BitmapDescriptor.hueGreen;
    } else if (magnitude < 5.0) {
      hue = BitmapDescriptor.hueYellow;
    } else if (magnitude < 7.0) {
      hue = BitmapDescriptor.hueOrange;
    } else {
      hue = BitmapDescriptor.hueRed;
    }
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }
}
