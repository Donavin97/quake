import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'models/earthquake.dart';
import 'providers/disclaimer_provider.dart';
import 'providers/earthquake_provider.dart';
import 'providers/location_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'routes.dart';
import 'services/navigation_service.dart';
import 'services/services.dart';
import 'theme.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Hive.initFlutter();
    Hive.registerAdapter(EarthquakeAdapter());
    Hive.registerAdapter(EarthquakeSourceAdapter());
    await Hive.openBox<Earthquake>('earthquakes');

    await BackgroundService.initialize();

    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
    final String? launchPayload =
        notificationAppLaunchDetails?.notificationResponse?.payload;
    if (launchPayload != null) {
      NavigationService.initialRoute = '/details/$launchPayload';
    }

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    runApp(const MyApp());
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        Provider<WebSocketService>(
          create: (_) => WebSocketService(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider(
          create: (context) => UserProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => LocationProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsProvider(context.read<LocationProvider>()),
        ),
        ChangeNotifierProvider(
          create: (context) => DisclaimerProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
        ChangeNotifierProxyProvider2<SettingsProvider, LocationProvider,
            EarthquakeProvider>(
          create: (context) => EarthquakeProvider(
            context.read<ApiService>(),
            context.read<WebSocketService>(),
            context.read<SettingsProvider>(),
            context.read<LocationProvider>(),
          ),
          update: (context, settings, location, previous) =>
              previous!..updateSettings(settings),
        ),
      ],

      child: Builder(
        builder: (context) {
          final userProvider = Provider.of<UserProvider>(context);
          final router = AppRouter(userProvider).router;

          return Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return MaterialApp.router(
                routerConfig: router,
                title: 'QuakeTrack',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: settingsProvider.themeMode,
              );
            },
          );
        },
      ),
    );
  }
}
