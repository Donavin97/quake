
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/earthquake.dart';
import '../providers/earthquake_provider.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final earthquakeProvider = Provider.of<EarthquakeProvider>(context);

    return Scaffold(
      body: ListView.builder(
        itemCount: earthquakeProvider.earthquakes.length,
        itemBuilder: (context, index) {
          final earthquake = earthquakeProvider.earthquakes[index];
          return ListTile(
            title: Text(earthquake.place),
            subtitle: Text('Magnitude: ${earthquake.magnitude}'),
            onTap: () {
              context.go('/details', extra: earthquake);
            },
          );
        },
      ),
    );
  }
}
