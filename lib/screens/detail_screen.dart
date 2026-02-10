import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geodesy/geodesy.dart';

import 'package:eq_track/models/earthquake.dart';

class DetailScreen extends StatefulWidget {
  final Earthquake earthquake;

  const DetailScreen({super.key, required this.earthquake});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
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
      setState(() {
        distance = calculatedDistance / 1000; // Convert to km
      });
    } catch (e) {
      print('Error calculating distance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Earthquake Details', style: GoogleFonts.oswald()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.earthquake.place,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
                'Magnitude: ${widget.earthquake.magnitude.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
                'Time: ${DateFormat.yMMMd().add_jms().format(widget.earthquake.time)}'),
            const SizedBox(height: 8),
            Text(
              'Coordinates: (${widget.earthquake.latitude.toStringAsFixed(2)}, ${widget.earthquake.longitude.toStringAsFixed(2)})',
            ),
            if (distance != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Distance: ${distance!.toStringAsFixed(2)} km'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}