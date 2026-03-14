import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/app_localizations.dart';

import '../models/notification_profile.dart';
import '../providers/earthquake_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/earthquake_list_item.dart';
import '../widgets/skeleton_item.dart';

class ListScreen extends ConsumerStatefulWidget {
  final void Function(int) navigateTo;
  const ListScreen({super.key, required this.navigateTo});

  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.orange),
            SizedBox(width: 10),
            Text('Quick Guide'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTutorialItem(
                'Magnitude (M)',
                'Measures the size of the earthquake at its source.\n'
                '• 3.0: Rarely felt but recorded.\n'
                '• 5.0: Felt by many; minor damage possible.\n'
                '• 7.0+: Major event; severe local damage.',
              ),
              const SizedBox(height: 12),
              _buildTutorialItem(
                'Depth (km)',
                'Distance below the Earth\'s surface.\n'
                '• 0-70km: Shallow (often more damage).\n'
                '• 70-300km: Intermediate.\n'
                '• 300km+: Deep.',
              ),
              const SizedBox(height: 12),
              _buildTutorialItem(
                'Theoretical Felt Radius',
                'Estimated area where the quake was felt. Shown as circles on the map.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Watch critical states
    final isSettingsLoaded = ref.watch(settingsProvider.select((s) => s.isLoaded));
    final currentProfile = ref.watch(earthquakeNotifierProvider.select((s) => s.filterNotificationProfile));
    final isArchiveMode = ref.watch(earthquakeNotifierProvider.select((s) => s.isArchiveMode));
    final archiveQuakes = ref.watch(earthquakeNotifierProvider.select((s) => s.archiveEarthquakes));
    final displayQuakes = ref.watch(earthquakeNotifierProvider.select((s) => s.displayEarthquakes));
    final isSearchingArchive = ref.watch(earthquakeNotifierProvider.select((s) => s.isSearchingArchive));
    final isProcessing = ref.watch(earthquakeNotifierProvider.select((s) => s.isProcessing));
    final lastUpdated = ref.watch(earthquakeNotifierProvider.select((s) => s.lastUpdated));
    final error = ref.watch(earthquakeNotifierProvider.select((s) => s.error));
    
    final profiles = ref.watch(settingsProvider.select((s) => s.userPreferences.notificationProfiles));
    
    // Show skeleton if settings are still loading
    if (!isSettingsLoaded) {
      return const EarthquakeListSkeleton();
    }

    NotificationProfile? dropdownValue;
    if (profiles.any((p) => p.id == currentProfile?.id)) {
      dropdownValue = profiles.firstWhere((p) => p.id == currentProfile?.id);
    } else if (profiles.isNotEmpty) {
      dropdownValue = profiles.first;
    } else {
      dropdownValue = currentProfile;
    }

    final sourceList = isArchiveMode ? archiveQuakes : displayQuakes;

    final filteredEarthquakes = _searchQuery.isEmpty
        ? sourceList
        : sourceList.where((eq) {
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: isArchiveMode ? l10n.searchArchive : l10n.searchPlace,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                    if (isArchiveMode) ref.read(earthquakeNotifierProvider.notifier).searchGlobalArchive('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onSubmitted: (value) {
                          if (isArchiveMode) {
                            ref.read(earthquakeNotifierProvider.notifier).searchGlobalArchive(value);
                          }
                        },
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      onPressed: _showTutorialDialog,
                      tooltip: 'Help',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: isArchiveMode 
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              l10n.archiveToggle,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          )
                        : Row(
                            children: [
                              const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: dropdownValue != null 
                                  ? DropdownButton<NotificationProfile>(
                                      isExpanded: true,
                                      value: dropdownValue,
                                      underline: const SizedBox(), // Cleaner look
                                      items: profiles.map((profile) {
                                        return DropdownMenuItem(
                                          value: profile,
                                          child: Text(
                                            profile.name,
                                            style: const TextStyle(fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (profile) {
                                        if (profile != null) {
                                          ref.read(earthquakeNotifierProvider.notifier).setFilterProfile(profile);
                                        }
                                      },
                                    )
                                  : const Text('No profiles', style: TextStyle(color: Colors.grey, fontSize: 14)),
                              ),
                            ],
                          ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.archiveToggle, style: const TextStyle(fontSize: 12)),
                      selected: isArchiveMode,
                      onSelected: (selected) {
                        ref.read(earthquakeNotifierProvider.notifier).toggleArchiveMode(selected);
                        if (selected && _searchQuery.isNotEmpty) {
                          ref.read(earthquakeNotifierProvider.notifier).searchGlobalArchive(_searchQuery);
                        }
                      },
                      selectedColor: Colors.orange.withAlpha(50),
                      checkmarkColor: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (isSearchingArchive)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 16),
                    Text('Searching global archive...'),
                  ],
                ),
              ),
            )
          else if (isProcessing && sourceList.isEmpty || lastUpdated == null && isProcessing)
            const Expanded(child: EarthquakeListSkeleton())
          else ...[
            if (lastUpdated != null && !isProcessing && !isArchiveMode)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  error ??
                      'Last updated: ${DateFormat.jms().format(lastUpdated.toLocal())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: error != null
                        ? Colors.red
                        : Colors.grey,
                  ),
                ),
              ),
            
            if (filteredEarthquakes.isNotEmpty)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (isArchiveMode) {
                      await ref.read(earthquakeNotifierProvider.notifier).searchGlobalArchive(_searchQuery);
                    } else {
                      ref.read(earthquakeNotifierProvider.notifier).refresh();
                      await Future.delayed(const Duration(milliseconds: 500));
                    }
                  },
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
              )
            else if (!isProcessing)
              Expanded(
                child: Center(
                  child: Text(isArchiveMode ? l10n.noArchiveData : l10n.noData),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
