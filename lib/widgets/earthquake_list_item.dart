import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geodesy/geodesy.dart';

import '../models/earthquake.dart';

class EarthquakeListItem extends StatefulWidget {
  final Earthquake earthquake;
  final VoidCallback onTap;

  const EarthquakeListItem({
    super.key,
    required this.earthquake,
    required this.onTap,
  });

  @override
  State<EarthquakeListItem> createState() => _EarthquakeListItemState();
}

class _EarthquakeListItemState extends State<EarthquakeListItem> {
  double? distance;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final userLocation = LatLng(position.latitude, position.longitude);
      final earthquakeLocation =
          LatLng(widget.earthquake.latitude, widget.earthquake.longitude);
      final calculatedDistance =
          Geodesy().distanceBetweenTwoGeoPoints(userLocation, earthquakeLocation);
      if (mounted) {
        setState(() {
          distance = calculatedDistance / 1000; // Convert to km
        });
      }
    } catch (e) {
      // Silently ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = StringBuffer(widget.earthquake.time.toString());
    if (distance != null) {
      subtitle.write(' - ${distance?.toStringAsFixed(1)} km away');
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            widget.earthquake.magnitude.toStringAsFixed(2),
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(widget.earthquake.place, style: GoogleFonts.openSans()),
        subtitle: Text(subtitle.toString()),
        onTap: widget.onTap,
      ),
    );
  }
}
