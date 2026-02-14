import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/earthquake.dart';
import '../providers/location_provider.dart';

class EarthquakeListItem extends StatelessWidget {
  final Earthquake earthquake;

  const EarthquakeListItem({super.key, required this.earthquake});

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final currentPosition = locationProvider.currentPosition;

    double? distanceInMeters;
    if (currentPosition != null) {
      distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        earthquake.latitude,
        earthquake.longitude,
      );
    }

    final formattedDate = DateFormat.yMMMd().format(earthquake.time);
    final formattedTime = DateFormat.jm().format(earthquake.time);
    final distanceInKm = distanceInMeters != null ? (distanceInMeters / 1000).toStringAsFixed(2) : 'N/A';

    return Semantics(
      label: 'Earthquake: ${earthquake.place}, Magnitude: ${earthquake.magnitude}, Date: $formattedDate at $formattedTime, Distance: $distanceInKm km',
      child: ListTile(
        title: Text(earthquake.place),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Magnitude: ${earthquake.magnitude}'),
            Text('Date: $formattedDate at $formattedTime'),
            if (distanceInMeters != null)
              Text('Distance: $distanceInKm km'),
          ],
        ),
        onTap: () {
          context.go('/details/${earthquake.id}', extra: earthquake);
        },
      ),
    );
  }
}
