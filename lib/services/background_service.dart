import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/earthquake.dart';
import 'navigation_service.dart';

import '../models/user_preferences.dart';
import '../models/notification_profile.dart';
import '../firebase_options.dart';

// Must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Ensure Firebase is initialized.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final prefs = await SharedPreferences.getInstance();

    // CRITICAL: Early exit if notifications are disabled in settings
    final bool notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    if (!notificationsEnabled) {
      debugPrint('Background handler: Notifications are disabled in app settings. Skipping.');
      return;
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          'earthquake_category',
          actions: [
            DarwinNotificationAction.plain('map_action', 'Map', options: {DarwinNotificationActionOption.foreground}),
            DarwinNotificationAction.plain('share_action', 'Share', options: {DarwinNotificationActionOption.foreground}),
            DarwinNotificationAction.plain('felt_action', 'I Felt It', options: {DarwinNotificationActionOption.foreground}),
          ],
        ),
      ],
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    
    await BackgroundService.flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    await BackgroundService.setupNotificationChannel();

    final earthquakeData = message.data['earthquake'] as String?;
    
    if (earthquakeData != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(earthquakeData);
        final earthquake = Earthquake.fromJson(decoded);
        
        final shouldShow = await BackgroundService.shouldShowNotification(earthquake, prefs, data: message.data);

        if (shouldShow) {
          await BackgroundService.showNotification(message, prefs);
        }
      } catch (e) {
        debugPrint('Error parsing earthquake in background: $e');
      }
    }
  } catch (e, stack) {
    debugPrint('CRITICAL: Background message handler crashed: $e');
    debugPrint(stack.toString());
  }
}

class BackgroundService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static final StreamController<Earthquake> _onEarthquakeReceivedController =
      StreamController<Earthquake>.broadcast();

  static Stream<Earthquake> get onEarthquakeReceived =>
      _onEarthquakeReceivedController.stream;

  static Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;

  static Future<void> setupNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'earthquake_channel',
      'Earthquake Alerts',
      description: 'Notifications for new earthquake events',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('earthquake'),
    );

    const AndroidNotificationChannel largeChannel = AndroidNotificationChannel(
      'earthquake_large_channel',
      'Large Earthquake Alerts',
      description: 'Notifications for significant earthquake events (magnitude 6.0+)',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('earthquake_large'),
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(largeChannel);
  }

  static Future<void> initialize() async {
    await setupNotificationChannel();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final List<DarwinNotificationAction> iosActions = [
      DarwinNotificationAction.plain('map_action', 'Map', options: {DarwinNotificationActionOption.foreground}),
      DarwinNotificationAction.plain('share_action', 'Share', options: {DarwinNotificationActionOption.foreground}),
      DarwinNotificationAction.plain('felt_action', 'I Felt It', options: {DarwinNotificationActionOption.foreground}),
    ];

    final List<DarwinNotificationCategory> iosCategories = [
      DarwinNotificationCategory(
        'earthquake_category',
        actions: iosActions,
      ),
    ];

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      notificationCategories: iosCategories,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.payload == null) return;

        final payloadData = jsonDecode(details.payload!);
        final earthquake = Earthquake.fromJson(payloadData['earthquake']);
        final context = NavigationService.navigatorKey.currentContext;

        if (details.actionId == 'map_action') {
          if (context != null) {
            GoRouter.of(context).go('/details/${Uri.encodeComponent(earthquake.id)}');
          }
        } else if (details.actionId == 'share_action') {
          final String timeStr = DateFormat.yMMMd().add_jms().format(earthquake.time.toLocal());
          final String mapUrl = 'https://www.google.com/maps/search/?api=1&query=${earthquake.latitude},${earthquake.longitude}';
          
          final String shareText = 'Earthquake Alert!\n\n'
              'Magnitude: ${earthquake.magnitude.toStringAsFixed(earthquake.source == EarthquakeSource.sec ? 2 : 1)}\n'
              'Location: ${earthquake.place}\n'
              'Time: $timeStr\n'
              'Source: ${earthquake.source.name.toUpperCase()}\n\n'
              'Epicenter: $mapUrl\n\n'
              'Shared via QuakeTrack';

          await SharePlus.instance.share(
            ShareParams(
              text: shareText,
              subject: 'Earthquake in ${earthquake.place}',
            ),
          );
        } else if (details.actionId == 'felt_action') {
          if (context != null) {
            GoRouter.of(context).go('/details/${Uri.encodeComponent(earthquake.id)}');
          }
        } else {
          if (context != null) {
            GoRouter.of(context).go('/details/${Uri.encodeComponent(earthquake.id)}');
          }
        }
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final prefs = await SharedPreferences.getInstance();
      final earthquakeData = message.data['earthquake'] as String?;
      if (earthquakeData != null) {
        final earthquake = Earthquake.fromJson(jsonDecode(earthquakeData));
        if (await shouldShowNotification(earthquake, prefs, data: message.data)) {
           _handleForegroundMessage(message, prefs);
        }
      }
    });
  }

  static Future<bool> shouldShowNotification(Earthquake earthquake, SharedPreferences prefs, {Map<String, dynamic>? data}) async {
    final bool notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    if (!notificationsEnabled) return false;

    // Check for duplicates
    final String? cachedJson = prefs.getString('cached_earthquakes');
    if (cachedJson != null) {
      final List<dynamic> list = jsonDecode(cachedJson);
      // We don't need to parse everything, just check IDs if possible.
      // But IDs are inside objects.
      // Optimized check:
      if (list.any((e) => e['id'] == earthquake.id)) {
        return false;
      }
    }

    // 0. Server Override
    if (data != null && data['isTargeted'] == 'true') {
      return true;
    }

    // 1. Get User Location
    double? userLat = prefs.getDouble('lastLatitude');
    double? userLon = prefs.getDouble('lastLongitude');
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 2), accuracy: LocationAccuracy.low),
      );
      userLat = position.latitude;
      userLon = position.longitude;
    } catch (_) {}

    // 2. Load Profiles from UserPreferences JSON
    final List<NotificationProfile> profilesToCheck = [];
    final String? userPrefsJson = prefs.getString('userPreferences');
    if (userPrefsJson != null) {
      try {
        final userPrefs = UserPreferences.fromJson(jsonDecode(userPrefsJson));
        profilesToCheck.addAll(userPrefs.notificationProfiles);
      } catch (e) {
        debugPrint('Error parsing user preferences in background: $e');
      }
    }
    
    // Fallback
    if (profilesToCheck.isEmpty) {
      // Create legacy profile from individual keys if available?
      // For now, let's assume if no profiles, we use default global settings if stored
      profilesToCheck.add(NotificationProfile(
        id: 'legacy',
        name: 'Legacy Profile',
        latitude: userLat ?? 0.0,
        longitude: userLon ?? 0.0,
        radius: prefs.getDouble('radius') ?? 0.0,
        minMagnitude: prefs.getDouble('minMagnitude') ?? 0.0,
      ));
    }

    // 3. Iterate Profiles
    for (final profile in profilesToCheck) {
      if (_checkProfile(earthquake, profile, userLat, userLon)) {
        return true; 
      }
    }

    return false;
  }

  static bool _checkProfile(Earthquake earthquake, NotificationProfile profile, double? userLat, double? userLon) {
    final double refLat = (profile.latitude != 0.0 || profile.longitude != 0.0) ? profile.latitude : (userLat ?? 0.0);
    final double refLon = (profile.latitude != 0.0 || profile.longitude != 0.0) ? profile.longitude : (userLon ?? 0.0);
    
    final double distance = _getDistance(refLat, refLon, earthquake.latitude, earthquake.longitude);
    
    if (profile.globalMinMagnitudeOverrideQuietHours > 0 && earthquake.magnitude >= profile.globalMinMagnitudeOverrideQuietHours) {
        return true;
    }
    if (profile.alwaysNotifyRadiusEnabled && profile.alwaysNotifyRadiusValue > 0 && distance <= profile.alwaysNotifyRadiusValue) {
        return true;
    }

    if (earthquake.magnitude < profile.minMagnitude) return false;
    
    if (profile.radius > 0 && distance > profile.radius) return false;

    if (profile.quietHoursEnabled) {
        if (_isDuringQuietHoursForProfile(profile)) {
             if (earthquake.magnitude >= profile.emergencyMagnitudeThreshold) {
                 if (distance <= profile.emergencyRadius) return true;
             }
             return false;
        }
    }
    
    return true;
  }

  static bool _isDuringQuietHoursForProfile(NotificationProfile profile) {
    final localNow = DateTime.now();

    if (!profile.quietHoursDays.contains(localNow.weekday % 7)) return false;

    final currentMinutes = localNow.hour * 60 + localNow.minute;
    final startMinutes = profile.quietHoursStart[0] * 60 + profile.quietHoursStart[1];
    final endMinutes = profile.quietHoursEnd[0] * 60 + profile.quietHoursEnd[1];

    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  static double _getDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; 
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degree) => degree * pi / 180;

  static Future<void> _handleForegroundMessage(RemoteMessage message, SharedPreferences prefs) async {
    final earthquakeData = message.data['earthquake'] as String?;
    if (earthquakeData != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(earthquakeData);
        final String id = decoded['id'] ?? '';
        
        // Check cache
        final String? cachedJson = prefs.getString('cached_earthquakes');
        if (cachedJson != null) {
           final List<dynamic> list = jsonDecode(cachedJson);
           if (list.any((e) => e['id'] == id)) {
             return;
           }
        }
      } catch (e) {
      }
    }
    await showNotification(message, prefs);
  }

  static Future<AuthorizationStatus> requestPermission() async {
    final NotificationSettings settings = await _firebaseMessaging.requestPermission();
    return settings.authorizationStatus;
  }

  static Future<AuthorizationStatus> getNotificationStatus() async {
    final NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  static Future<void> showNotification(RemoteMessage message, SharedPreferences prefs) async {
    final title = message.data['title'] as String?;
    final body = message.data['body'] as String?;
    final earthquakeData = message.data['earthquake'] as String?;
    final mapUrl = message.data['mapUrl'] as String?;

    if (earthquakeData == null) {
      return;
    }

    final earthquake = Earthquake.fromJson(jsonDecode(earthquakeData));
    
    _onEarthquakeReceivedController.add(earthquake);

    // Save to cache
    final String? cachedJson = prefs.getString('cached_earthquakes');
    List<dynamic> list = [];
    if (cachedJson != null) {
      list = jsonDecode(cachedJson);
    }
    // Remove if exists (to update) or just add
    list.removeWhere((e) => e['id'] == earthquake.id);
    list.add(earthquake.toJson());
    // Limit cache size maybe?
    if (list.length > 500) {
      // Sort by time? Or just remove first/random?
      // Assuming list is somewhat ordered or we don't care about old ones.
      list.removeAt(0);
    }
    await prefs.setString('cached_earthquakes', jsonEncode(list));

    final payload = jsonEncode({
      'earthquake': jsonDecode(earthquakeData),
      'mapUrl': mapUrl,
    });

    final bool isLargeEarthquake = earthquake.magnitude >= 6.0;
    final String channelId = isLargeEarthquake ? 'earthquake_large_channel' : 'earthquake_channel';
    final String channelName = isLargeEarthquake ? 'Large Earthquake Alerts' : 'Earthquake Alerts';
    final String channelDescription = isLargeEarthquake
        ? 'Notifications for significant earthquake events (magnitude 6.0+)'
        : 'Notifications for new earthquake events';

    const String groupKey = 'com.quaketrack.EARTHQUAKE_ALERTS';

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      groupKey: groupKey,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'map_action',
          'Map',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'share_action',
          'Share',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'felt_action',
          'I Felt It',
          showsUserInterface: true,
        ),
      ],
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(
        threadIdentifier: 'earthquake_alerts',
        categoryIdentifier: 'earthquake_category',
      ),
    );

    final int notificationId = earthquake.id.hashCode;

    await flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );

    final String summaryChannelId = isLargeEarthquake ? 'earthquake_large_channel' : 'earthquake_channel';
    final String summaryChannelName = isLargeEarthquake ? 'Large Earthquake Alerts' : 'Earthquake Alerts';
    await flutterLocalNotificationsPlugin.show(
      id: 0, 
      title: '',
      body: '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          summaryChannelId,
          summaryChannelName,
          channelDescription: 'Notifications for earthquake events',
          importance: Importance.max,
          priority: Priority.high,
          groupKey: groupKey,
          setAsGroupSummary: true,
        ),
      ),
    );
  }


  static Future<String?> getFCMToken() async {
    return _firebaseMessaging.getToken();
  }
}
