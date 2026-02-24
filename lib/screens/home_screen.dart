import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // For AuthorizationStatus
import 'package:geolocator/geolocator.dart'; // For Geolocator.openAppSettings
import 'package:url_launcher/url_launcher.dart'; // For opening app settings

import '../models/sort_criterion.dart';
import '../providers/earthquake_provider.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart'; // Explicitly import SettingsProvider
import '../services/services.dart';
import 'list_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;
  bool _askedLocationPermission = false;
  bool _askedNotificationPermission = false;

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer
    _requestPermissions(context); // Request permissions after widget is built

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7112901918437892/4314697520', // User's Ad Unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
  }

  Future<void> _requestPermissions(BuildContext context) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    // --- Location Permissions ---
    if (!_askedLocationPermission) {
      await locationProvider.checkPermission();
      if (!locationProvider.isPermissionGranted) {
        // If not granted, try to request
        await locationProvider.requestPermission();
        if (locationProvider.isPermissionGranted) {
          // If granted after request, determine position
          locationProvider.determinePosition();
        } else {
          // Still not granted, show a message or guide to settings
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Location permission is required for radius-based alerts and list filtering.'),
                action: SnackBarAction(label: 'Settings', onPressed: () => Geolocator.openAppSettings()),
              ),
            );
          }
        }
      } else {
        // Permission already granted, just determine position
        locationProvider.determinePosition();
      }
      _askedLocationPermission = true;
    }

    // --- Notification Permissions ---
    if (!_askedNotificationPermission) {
      // Check if notifications are enabled in user preferences
      // Note: settingsProvider.notificationsEnabled might be true from preferences,
      // but actual OS permission might be denied after reinstallation.
      final AuthorizationStatus currentStatus = await BackgroundService.getNotificationStatus(); // Get current OS status
      if (currentStatus == AuthorizationStatus.denied || currentStatus == AuthorizationStatus.notDetermined) {
        final AuthorizationStatus status = await BackgroundService.requestPermission();
        if (status == AuthorizationStatus.denied) {
          // User denied permissions permanently, update internal state
          await settingsProvider.setNotificationsEnabled(false); // This saves and notifies
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Notification permission is required for earthquake alerts.'),
                action: SnackBarAction(label: 'Settings', onPressed: () => _openAppSettingsForNotifications()), // Use helper
              ),
            );
          }
        } else if (status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional) {
          // If granted or provisional, ensure subscriptions are updated
          await settingsProvider.setNotificationsEnabled(true); // This saves and updates subscriptions
        }
      } else if (currentStatus == AuthorizationStatus.authorized || currentStatus == AuthorizationStatus.provisional) {
          // Permissions already granted at OS level, ensure app state is enabled
          if (!settingsProvider.notificationsEnabled) {
            await settingsProvider.setNotificationsEnabled(true); // This saves and updates subscriptions
          }
      }
      _askedNotificationPermission = true;
    }
  }

  Future<void> _openAppSettingsForNotifications() async {
    // This is a generic way to open app settings. Behavior can vary by platform.
    // A more robust solution might use platform-specific intents or packages like `app_settings`.
    await launchUrl(Uri.parse('app-settings:'));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app resumes from background, re-check permissions
      _requestPermissions(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    _bannerAd.dispose();
    super.dispose();
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
          tooltip: 'Menu',
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
          icon: const Icon(Icons.more_vert),
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
      body: Column(
        children: [
          Expanded(child: screens[_currentIndex]),
          if (_isAdLoaded)
            SizedBox(
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
        ],
      ),
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
