import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'notification_service.dart';
import 'providers/disclaimer_provider.dart';
import 'providers/earthquake_provider.dart';
import 'providers/location_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'routes.dart';
import 'services/services.dart';
import 'theme.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await BackgroundService.initialize();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    runApp(const MyApp());
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter router;
  late final UserProvider userProvider;
  late final NotificationService notificationService;

  @override
  void initState() {
    super.initState();
    userProvider = UserProvider();
    notificationService = NotificationService();
    router = AppRouter(userProvider, notificationService).router;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: AuthService()),
        Provider<NotificationService>.value(
          value: notificationService,
        ),
        ChangeNotifierProvider(create: (context) => LocationProvider()),
        ChangeNotifierProxyProvider<AuthService, SettingsProvider>(
          create: (context) => SettingsProvider(),
          update: (context, auth, settings) => settings!..setAuthService(auth),
        ),
        ChangeNotifierProvider(create: (context) => DisclaimerProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProxyProvider<SettingsProvider, EarthquakeProvider>(
          create: (context) =>
              EarthquakeProvider(context.read<SettingsProvider>()),
          update: (context, settings, previous) =>
              previous!..updateSettings(settings),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            routerConfig: router,
            title: 'QuakeTrack',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
          );
        },
      ),
    );
  }
}
