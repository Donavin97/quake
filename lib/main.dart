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
    final notificationService = NotificationService();
    await notificationService.init();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    runApp(MyApp(notificationService: notificationService));
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack));
}

class MyApp extends StatefulWidget {
  final NotificationService notificationService;
  const MyApp({super.key, required this.notificationService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthService authService;
  late final GoRouter router;
  late final DisclaimerProvider disclaimerProvider;
  late final LocationProvider locationProvider;
  late final UserProvider userProvider;

  @override
  void initState() {
    super.initState();
    disclaimerProvider = DisclaimerProvider();
    authService = AuthService();
    locationProvider = LocationProvider();
    userProvider = UserProvider();

    router = AppRouter(
      disclaimerProvider,
      authService,
      locationProvider,
      widget.notificationService,
      userProvider,
    ).router;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<NotificationService>.value(
          value: widget.notificationService,
        ),
        ChangeNotifierProvider.value(value: locationProvider),
        ChangeNotifierProxyProvider<AuthService, SettingsProvider>(
          create: (context) => SettingsProvider(),
          update: (context, auth, settings) => settings!..setAuthService(auth),
        ),
        ChangeNotifierProvider.value(value: disclaimerProvider),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProxyProvider<SettingsProvider, EarthquakeProvider>(
          create: (context) =>
              EarthquakeProvider(context.read<SettingsProvider>())..fetchEarthquakes(),
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
