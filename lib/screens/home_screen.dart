import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import '../generated/app_localizations.dart';

import '../models/earthquake.dart';
import '../models/sort_criterion.dart';
import '../providers/earthquake_provider.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../providers/safety_provider.dart';
import '../providers/service_providers.dart';
import '../services/navigation_service.dart';
import '../services/services.dart';
import '../theme.dart';
import '../config/app_config.dart';
import 'list_screen.dart';
import 'map_screen.dart';
import 'statistics_screen.dart';
import 'safety_screen.dart';
import 'settings_screen.dart';
import 'circles_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  BannerAd? _bannerAd;
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
    WidgetsBinding.instance.addObserver(this);
    
    // Handle initial route from shortcuts
    if (NavigationService.initialRoute == '/safety_tab') {
      _currentIndex = 3; 
      NavigationService.initialRoute = null;
    }

    // Trigger permissions and initial state
    Future.microtask(() => _requestPermissions());
  }

  void _showSafetyCheckDialog(Earthquake quake) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Are you safe?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A significant earthquake (${quake.magnitude}) occurred near your location.'),
            const SizedBox(height: 16),
            const Text('Mark your status for your Safety Circles:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(safetyProvider.notifier).ignore();
              Navigator.pop(context);
            },
            child: const Text('IGNORE'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(safetyProvider.notifier).markUnsafe();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('I NEED HELP'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(safetyProvider.notifier).markSafe();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('I AM SAFE'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) {
      _bannerAd = BannerAd(
        adUnitId: AppConfig.homeBannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isAdLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('Failed to load a banner ad: ${err.message}');
            ad.dispose();
          },
        ),
      );
      _bannerAd!.load();
    }
  }

  Future<void> _requestPermissions() async {
    final userState = ref.read(userNotifierProvider);
    if (!userState.isSetupComplete) return;

    await _requestLocationPermissions();
    await _requestNotificationPermissions();
  }

  Future<void> _requestLocationPermissions() async {
    if (_askedLocationPermission) return;

    final locationNotifier = ref.read(locationProvider.notifier);
    
    // In current locationNotifier, checkPermission doesn't exist, it's called in build
    // But determinePosition exists.
    
    final locationState = ref.read(locationProvider);

    if (!locationState.permissionGranted) {
      await locationNotifier.requestPermission();
      final updatedState = ref.read(locationProvider);
      if (updatedState.permissionGranted) {
        locationNotifier.determinePosition();
      } else {
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
      locationNotifier.determinePosition();
    }
    _askedLocationPermission = true;
  }

  Future<void> _requestNotificationPermissions() async {
    if (_askedNotificationPermission) return;

    final settingsNotifier = ref.read(settingsProvider.notifier);
    final settingsState = ref.read(settingsProvider);

    final AuthorizationStatus currentStatus = await BackgroundService.getNotificationStatus();

    if (currentStatus == AuthorizationStatus.denied || currentStatus == AuthorizationStatus.notDetermined) {
      final AuthorizationStatus status = await BackgroundService.requestPermission();
      if (status == AuthorizationStatus.denied) {
        await settingsNotifier.setNotificationsEnabled(false);
      } else if (status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional) {
        await settingsNotifier.setNotificationsEnabled(true);
      }
    } else if (currentStatus == AuthorizationStatus.authorized || currentStatus == AuthorizationStatus.provisional) {
        if (!settingsState.userPreferences.notificationsEnabled) {
          await settingsNotifier.setNotificationsEnabled(true);
        }
    }
    _askedNotificationPermission = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _requestPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eqState = ref.watch(earthquakeNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    // Listen to safety checks
    ref.listen(safetyProvider, (previous, next) {
      if (next.pendingSafetyCheck != null && previous?.pendingSafetyCheck == null) {
        _showSafetyCheckDialog(next.pendingSafetyCheck!);
      }
    });

    // Listen to navigation service tab changes
    ref.listen(navigationServiceTabProvider, (previous, next) {
      final index = next.value;
      if (index != null) {
        setState(() {
          _currentIndex = index;
        });
      }
    });

    final List<Widget> screens = [
      const MapScreen(),
      ListScreen(navigateTo: _navigateTo),
      const StatisticsScreen(),
      const CirclesScreen(),
      const SafetyScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? AppTheme.obsidian 
            : Theme.of(context).primaryColor,
        leading: PopupMenuButton<String>(
          tooltip: 'Menu',
          onSelected: (value) async {
            final authService = ref.read(authServiceProvider);
            if (value == 'profile') {
              context.go('/profile');
            } else if (value == 'statistics') {
              setState(() {
                _currentIndex = 2;
              });
            } else if (value == 'signOut') {
              await authService.signOut();
              if (context.mounted) context.go('/auth');
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'profile',
              child: Text(l10n.profile),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'signOut',
              child: Text(l10n.signOut),
            ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
        title: Text(l10n.appTitle),
        actions: [
          if (_currentIndex == 1)
            DropdownButton<SortCriterion>(
              value: eqState.sortCriterion,
              onChanged: (value) {
                if (value != null) {
                  ref.read(earthquakeNotifierProvider.notifier).setSortCriterion(value);
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
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
          if (_isAdLoaded && _bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == 5) {
            final authService = ref.read(authServiceProvider);
            if (authService.currentUser == null) {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.authRequired),
                  content: Text(l10n.authRequiredMessage),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/auth');
                      },
                      child: Text(l10n.signIn),
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
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: l10n.mapTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: l10n.listTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: l10n.statsTab,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Circles',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.emergency_outlined),
            label: l10n.safetyTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settingsTab,
          ),
        ],
      ),
    );
  }
}

final navigationServiceTabProvider = StreamProvider<int?>((ref) {
  final controller = StreamController<int?>();
  void listener() {
    if (!controller.isClosed) {
      controller.add(NavigationService.tabChangeNotifier.value);
    }
  }
  NavigationService.tabChangeNotifier.addListener(listener);
  ref.onDispose(() {
    NavigationService.tabChangeNotifier.removeListener(listener);
    controller.close();
  });
  return controller.stream;
});
