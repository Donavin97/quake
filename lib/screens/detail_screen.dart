import 'package:flutter/material.dart';
import '../models/earthquake.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailScreen extends StatelessWidget {
  final Earthquake earthquake;

  const DetailScreen({super.key, required this.earthquake});

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
              earthquake.place,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Magnitude: ${earthquake.magnitude.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Time: ${earthquake.time}'),
            const SizedBox(height: 8),
            Text(
              'Coordinates: (${earthquake.latitude.toStringAsFixed(2)}, ${earthquake.longitude.toStringAsFixed(2)})',
            ),
            const SizedBox(height: 8),
            Text('Depth: ${earthquake.depth.toStringAsFixed(2)} km'),
          ],
        ),
      ),
    );
  }
}
