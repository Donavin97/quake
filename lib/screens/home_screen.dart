import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/sort_criterion.dart';
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

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    locationProvider.determinePosition();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final earthquakeProvider = Provider.of<EarthquakeProvider>(context);

    final List<Widget> screens = [
      const MapScreen(),
      ListScreen(navigateTo: _navigateTo),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: PopupMenuButton<String>(
          onSelected: (value) async {
            final router = GoRouter.of(context);
            if (value == 'profile') {
              router.go('/profile');
            } else if (value == 'signOut') {
              await authService.signOut();
              router.go('/auth');
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'profile',
              child: Text('Profile'),
            ),
            const PopupMenuItem<String>(
              value: 'signOut',
              child: Text('Sign Out'),
            ),
          ],
        ),
        title: const Text('QuakeTrack'),
        actions: [
          if (_currentIndex == 1)
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
                  child: Text(criterion.name[0].toUpperCase() +
                      criterion.name.substring(1)),
                );
              }).toList(),
            ),
        ],
      ),
      body: screens[_currentIndex],
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
