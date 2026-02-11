import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sort_criterion.dart';
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
      body: Column(
        children: [
          if (earthquakeProvider.lastUpdated != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last updated: ${DateFormat.yMMMd().add_jms().format(earthquakeProvider.lastUpdated!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  DropdownButton<SortCriterion>(
                    value: earthquakeProvider.sortCriterion,
                    onChanged: (value) {
                      if (value != null) {
                        earthquakeProvider.setSortCriterion(value);
                      }
                    },
                    items: SortCriterion.values.map((criterion) {
                      return DropdownMenuItem(
                        value: criterion,
                        child: Text(toBeginningOfSentenceCase(criterion.name)!),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
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
          ),
        ],
      ),
    );
  }
}
