import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/earthquake_provider.dart';
import '../providers/location_provider.dart';
import '../services/services.dart';
import 'list_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapScreen(),
    const ListScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final earthquakeProvider = Provider.of<EarthquakeProvider>(context, listen: false);
    locationProvider.determinePosition().then((_) {
      if (locationProvider.currentPosition != null) {
        earthquakeProvider.fetchEarthquakes(position: locationProvider.currentPosition);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuakeTrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              final router = GoRouter.of(context);
              await authService.signOut();
              router.go('/auth');
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == 2) {
            if (authService.currentUser == null) {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Authentication Required'),
                  content: const Text(
                      'Please sign in to access and modify settings.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/auth');
                      },
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              );
              return;
            }
          }
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
