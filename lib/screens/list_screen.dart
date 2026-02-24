import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/notification_profile.dart'; // Import NotificationProfile
import '../providers/earthquake_provider.dart';
import '../providers/settings_provider.dart'; // Import SettingsProvider
import '../widgets/earthquake_list_item.dart';

class ListScreen extends StatefulWidget {
  final void Function(int) navigateTo;
  const ListScreen({super.key, required this.navigateTo});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late NotificationProfile _selectedProfile;

  @override
  void initState() {
    super.initState();
    _selectedProfile = Provider.of<EarthquakeProvider>(context, listen: false).filterNotificationProfile;
  }

  @override
  Widget build(BuildContext context) {
    final earthquakeProvider = Provider.of<EarthquakeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context); // Get SettingsProvider

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<NotificationProfile>(
              value: _selectedProfile,
              onChanged: (NotificationProfile? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedProfile = newValue;
                  });
                  earthquakeProvider.setFilterProfile(newValue); // Update EarthquakeProvider
                }
              },
              items: settingsProvider.notificationProfiles.map<DropdownMenuItem<NotificationProfile>>((NotificationProfile profile) {
                return DropdownMenuItem<NotificationProfile>(
                  value: profile,
                  child: Text(profile.name),
                );
              }).toList(),
            ),
          ),
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
