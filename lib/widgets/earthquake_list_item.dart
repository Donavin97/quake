import 'package:flutter/material.dart';

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
            earthquake.magnitude.toStringAsFixed(2),
          ),
        ),
        title: Text(earthquake.place),
        subtitle: Text(subtitle.toString()),
        onTap: onTap,
      ),
    );
  }
}
