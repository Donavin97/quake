import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sort_criterion.dart';
import '../providers/earthquake_provider.dart';
import '../widgets/earthquake_list_item.dart';

class ListScreen extends StatefulWidget {
  final void Function(int) navigateTo;
  const ListScreen({super.key, required this.navigateTo});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  @override
  Widget build(BuildContext context) {
    final earthquakeProvider = Provider.of<EarthquakeProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          if (earthquakeProvider.isProcessing)
            const LinearProgressIndicator(minHeight: 2),
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
          if (earthquakeProvider.error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Could not fetch earthquakes. Please try again.'),
                  ElevatedButton(
                    onPressed: () => earthquakeProvider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: earthquakeProvider.earthquakes.length,
                itemBuilder: (context, index) {
                  final earthquake = earthquakeProvider.earthquakes[index];
                  return EarthquakeListItem(
                    earthquake: earthquake,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
