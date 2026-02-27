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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedProfile = Provider.of<EarthquakeProvider>(context, listen: false).filterNotificationProfile;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earthquakeProvider = Provider.of<EarthquakeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context); // Get SettingsProvider

    // Filter earthquakes based on search query
    final filteredEarthquakes = _searchQuery.isEmpty
        ? earthquakeProvider.earthquakes
        : earthquakeProvider.earthquakes.where((eq) {
            final query = _searchQuery.toLowerCase();
            return eq.place.toLowerCase().contains(query) ||
                eq.magnitude.toString().contains(query) ||
                eq.id.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search earthquakes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButton<NotificationProfile>(
                  value: _selectedProfile,
                  isExpanded: true,
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
              ],
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
          else if (filteredEarthquakes.isEmpty && _searchQuery.isNotEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No earthquakes found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different search term',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredEarthquakes.length,
                itemBuilder: (context, index) {
                  final earthquake = filteredEarthquakes[index];
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
