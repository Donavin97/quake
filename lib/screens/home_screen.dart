import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/time_window.dart';
import '../providers/earthquake_provider.dart';
import '../providers/location_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/earthquake_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? fcmToken;

  @override
  void initState() {
    super.initState();
    // Fetch earthquakes when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      FirebaseMessaging.instance.getToken().then((token) {
        setState(() {
          fcmToken = token;
        });
      });
    });
  }

  Future<void> _fetchData() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.determinePosition();

    final earthquakeProvider = Provider.of<EarthquakeProvider>(context, listen: false);
    await earthquakeProvider.fetchEarthquakes(position: locationProvider.currentPosition);
  }

  void _showFilterAndTokenInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final minMagnitude = prefs.getDouble('minMagnitude') ?? 0.0;
    final radius = prefs.getDouble('radius') ?? 1000.0;
    final timeWindowIndex = prefs.getInt('timeWindow') ?? 0;
    final timeWindow = TimeWindow.values[timeWindowIndex];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Min Magnitude: $minMagnitude'),
            Text('Radius: $radius km'),
            Text('Time Window: $timeWindow'),
            Text('FCM Token: $fcmToken'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Earthquakes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showFilterAndTokenInfo,
            tooltip: 'Show Filters and Token',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer<EarthquakeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.earthquakes.isEmpty) {
            return const Center(child: Text('No earthquakes found.'));
          }

          return ListView.builder(
            itemCount: provider.earthquakes.length,
            itemBuilder: (context, index) {
              final earthquake = provider.earthquakes[index];
              return EarthquakeListItem(
                earthquake: earthquake,
                onTap: () {
                  context.go('/details', extra: earthquake);
                },
              );
            },
          );
        },
      ),
    );
  }
}
