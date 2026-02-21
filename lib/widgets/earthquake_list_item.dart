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

    final magPrecision = earthquake.source == EarthquakeSource.sec ? 2 : 1;
    final displayPlace = earthquake.place.contains(' km ') ? 'Near ${earthquake.place}' : earthquake.place;

    return Semantics(
      label: 'Earthquake: $displayPlace, Magnitude: ${earthquake.magnitude.toStringAsFixed(magPrecision)}, Date: $formattedDate at $formattedTime, Distance: $distanceInKm km',
      child: ListTile(
        title: Text(displayPlace),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Magnitude: ${earthquake.magnitude.toStringAsFixed(magPrecision)}'),
            Text('Date: $formattedDate at $formattedTime'),
            if (distanceInMeters != null)
              Text('Distance from you: $distanceInKm km'),
          ],
        ),
        onTap: () {
          context.go('/details/${Uri.encodeComponent(earthquake.id)}', extra: earthquake);
        },
      ),
    );
  }
}
