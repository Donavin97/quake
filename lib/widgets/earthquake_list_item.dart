import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../generated/app_localizations.dart';
import '../models/earthquake.dart';
import '../services/haptic_service.dart';

class EarthquakeListItem extends StatelessWidget {
  final Earthquake earthquake;

  const EarthquakeListItem({super.key, required this.earthquake});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final distanceInMeters = earthquake.distance;

    final formattedDate = DateFormat.yMMMd().format(earthquake.time.toLocal());
    final formattedTime = DateFormat.jm().format(earthquake.time.toLocal());
    final distanceInKm = distanceInMeters != null ? (distanceInMeters / 1000).toStringAsFixed(2) : 'N/A';

    final magPrecision = earthquake.source == EarthquakeSource.sec ? 2 : 1;
    final displayPlace = earthquake.place.contains(' km ') ? l10n.near(earthquake.place) : earthquake.place;

    return Semantics(
      label: '$displayPlace, ${l10n.magnitude}: ${earthquake.magnitude.toStringAsFixed(magPrecision)}, ${l10n.time}: $formattedDate at $formattedTime, ${l10n.distance}: $distanceInKm km',
      child: ListTile(
        title: Text(displayPlace),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.magnitude}: ${earthquake.magnitude.toStringAsFixed(magPrecision)}'),
            Text('${l10n.time}: $formattedDate $formattedTime'),
            if (distanceInMeters != null)
              Text(l10n.distanceFromYou(distanceInKm)),
          ],
        ),
        onTap: () {
          HapticService.vibrateForEarthquake(earthquake);
          context.go('/details/${Uri.encodeComponent(earthquake.id)}', extra: earthquake);
        },
      ),
    );
  }
}
