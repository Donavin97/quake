import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

import '../models/notification_profile.dart';
import '../providers/settings_provider.dart';
import '../providers/location_provider.dart'; // To get current location for new profile

class NotificationProfilesScreen extends ConsumerStatefulWidget {
  const NotificationProfilesScreen({super.key});

  @override
  ConsumerState<NotificationProfilesScreen> createState() => _NotificationProfilesScreenState();
}

class _NotificationProfilesScreenState extends ConsumerState<NotificationProfilesScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh profiles when app resumes
    if (state == AppLifecycleState.resumed) {
      setState(() {}); // Trigger rebuild to refresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final profiles = settingsState.userPreferences.notificationProfiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Profiles'),
      ),
      body: profiles.isEmpty
          ? const Center(
              child: Text('No notification profiles found. Create one!'),
            )
          : ListView.builder(
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return ListTile(
                  title: Text(profile.name),
                  subtitle: Text(
                      'Mag: ${profile.minMagnitude.toStringAsFixed(1)}, Rad: ${profile.radius == 0.0 ? 'Worldwide' : '${profile.radius.toStringAsFixed(0)} km'}'),
                  onTap: () {
                    ref.read(settingsProvider.notifier).setActiveNotificationProfile(profile);
                    // Navigate to a detail screen for editing this profile
                    context.go('/settings/notification_profile_detail/${profile.id}');
                  },
                  trailing: IconButton(
                    tooltip: 'Delete Profile',
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
                        await ref.read(settingsProvider.notifier).deleteProfile(profile.id);
                        if (!mounted) return;
                        // If the deleted profile was active, set a new active one or null
                        final updatedProfiles = ref.read(settingsProvider).userPreferences.notificationProfiles;
                        if (updatedProfiles.isEmpty) {
                          ref.read(settingsProvider.notifier).setActiveNotificationProfile(null); // No active profile
                        } else if (settingsState.activeNotificationProfile?.id == profile.id) { 
                          ref.read(settingsProvider.notifier).setActiveNotificationProfile(updatedProfiles.first); // Set first as active
                        }
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add New Profile',
        onPressed: () async {
          // Create a new default profile
          const uuid = Uuid();
          final newProfileId = uuid.v4();
          final locationState = ref.read(locationProvider);
          final settingsNotifier = ref.read(settingsProvider.notifier);
          final currentPosition = locationState.position;

          final newProfile = NotificationProfile(
            id: newProfileId,
            name: 'New Profile ${profiles.length + 1}',
            latitude: currentPosition?.latitude ?? 0.0,
            longitude: currentPosition?.longitude ?? 0.0,
            radius: 0.0,
            minMagnitude: 4.5,
          );
          await settingsNotifier.addProfile(newProfile);
          if (!context.mounted) return;
          settingsNotifier.setActiveNotificationProfile(newProfile); // Set new profile as active
          context.go('/settings/notification_profile_detail/$newProfileId'); // Navigate to edit
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
