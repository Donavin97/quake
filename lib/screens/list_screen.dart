import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/earthquake_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/earthquake_list_item.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final earthquakeProvider = Provider.of<EarthquakeProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => earthquakeProvider.fetchEarthquakes(
          position: locationProvider.currentPosition,
        ),
        child: ListView.builder(
          itemCount: earthquakeProvider.earthquakes.length,
          itemBuilder: (context, index) {
            final earthquake = earthquakeProvider.earthquakes[index];
            return EarthquakeListItem(
              earthquake: earthquake,
              onTap: () {
                context.go('/details', extra: earthquake);
              },
            );
          },
        ),
      ),
    );
  }
}
