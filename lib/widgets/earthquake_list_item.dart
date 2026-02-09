import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/earthquake.dart';

class EarthquakeListItem extends StatelessWidget {
  final Earthquake earthquake;
  final VoidCallback onTap;

  const EarthquakeListItem({
    super.key,
    required this.earthquake,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = StringBuffer(earthquake.time.toString());
    if (earthquake.distance != null) {
      subtitle.write(' - ${earthquake.distance?.toStringAsFixed(1)} km away');
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            earthquake.magnitude.toStringAsFixed(1),
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(earthquake.place, style: GoogleFonts.openSans()),
        subtitle: Text(subtitle.toString()),
        onTap: onTap,
      ),
    );
  }
}
