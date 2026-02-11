import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'notification_service.dart';
import 'providers/earthquake_provider.dart';
import 'providers/location_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'routes.dart';
import 'services/auth_service.dart';
import 'services/background_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await BackgroundService.initialize();
  // Create a single instance of NotificationService
  final notificationService = NotificationService();
  // Initialize it
  await notificationService.init();

  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatefulWidget {
  final NotificationService notificationService;
  const MyApp({super.key, required this.notificationService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Create single instances of AuthService and the router
  late final AuthService authService;
  late final GoRouter router;

  @override
  void initState() {
    super.initState();
    authService = AuthService();
    router = AppRouter(authService).router;
    widget.notificationService.checkPermission();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide the single instance of AuthService
        Provider<AuthService>.value(value: authService),
        // Provide the single instance of NotificationService
        Provider<NotificationService>.value(
          value: widget.notificationService,
        ),
        ChangeNotifierProvider(
            create: (context) => LocationProvider()..checkPermission()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(
          create: (context) => EarthquakeProvider()..fetchEarthquakes(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            // Use the single router instance
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
