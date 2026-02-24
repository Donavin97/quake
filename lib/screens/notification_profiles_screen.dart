import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

import '../models/notification_profile.dart';
import '../providers/settings_provider.dart';
import '../providers/location_provider.dart'; // To get current location for new profile

class NotificationProfilesScreen extends StatelessWidget {
  const NotificationProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Profiles'),
      ),
      body: settingsProvider.notificationProfiles.isEmpty
          ? const Center(
              child: Text('No notification profiles found. Create one!'),
            )
          : ListView.builder(
              itemCount: settingsProvider.notificationProfiles.length,
              itemBuilder: (context, index) {
                final profile = settingsProvider.notificationProfiles[index];
                return ListTile(
                  title: Text(profile.name),
                  subtitle: Text(
                      'Mag: ${profile.minMagnitude.toStringAsFixed(1)}, Rad: ${profile.radius == 0.0 ? 'Worldwide' : '${profile.radius.toStringAsFixed(0)} km'}'),
                  onTap: () {
                    settingsProvider.setActiveNotificationProfile(profile);
                    // Navigate to a detail screen for editing this profile
                    context.go('/settings/notification_profile_detail/${profile.id}');
                  },
                  trailing: IconButton(
                    tooltip: 'Delete Profile', // Add this line
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      // Confirm deletion
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: Text('Are you sure you want to delete profile "${profile.name}"?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirm == true) {
                        await settingsProvider.deleteProfile(profile.id);
                        // If the deleted profile was active, set a new active one or null
                        if (settingsProvider.notificationProfiles.isEmpty) {
                            settingsProvider.setActiveNotificationProfile(null); // No active profile
                        } else if (settingsProvider.minMagnitude == profile.minMagnitude.toInt()) { // Check if it was the active one by comparing a field (simplistic)
                             settingsProvider.setActiveNotificationProfile(settingsProvider.notificationProfiles.first); // Set first as active
                        }
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add New Profile', // Add this line
        onPressed: () async {
          // Create a new default profile
          const uuid = Uuid();
          final newProfileId = uuid.v4();
          final currentPosition = locationProvider.currentPosition;

          final newProfile = NotificationProfile(
            id: newProfileId,
            name: 'New Profile ${settingsProvider.notificationProfiles.length + 1}',
            latitude: currentPosition?.latitude ?? 0.0,
            longitude: currentPosition?.longitude ?? 0.0,
            radius: 0.0,
            minMagnitude: 4.5,
          );
          await settingsProvider.addProfile(newProfile);
          settingsProvider.setActiveNotificationProfile(newProfile); // Set new profile as active
          context.go('/settings/notification_profile_detail/$newProfileId'); // Navigate to edit
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// You will also need a detail screen (notification_profile_detail_screen.dart)
// where users can actually edit the settings of a NotificationProfile.
// This is a placeholder for navigation.