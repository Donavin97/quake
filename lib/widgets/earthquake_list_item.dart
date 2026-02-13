import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final subtitle =
        StringBuffer(DateFormat.yMMMd().add_jms().format(earthquake.time));
    if (earthquake.distance != null) {
      subtitle.write(' - ${(earthquake.distance! / 1000).toStringAsFixed(1)} km away');
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
        trailing: Text(earthquake.source.toString().split('.').last.toUpperCase()),
        onTap: onTap,
      ),
    );
  }
}
