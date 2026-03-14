import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/app_localizations.dart';

import 'firebase_options.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'routes.dart';
import 'services/services.dart';
import 'services/shortcut_service.dart';
import 'services/navigation_service.dart';
import 'theme.dart';
import 'widgets/global_error_view.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  debugPrint('--- [QUAKE_MAIN] main() started ---');
  await runZonedGuarded(() async {
    debugPrint('--- [QUAKE_MAIN] Inside runZonedGuarded ---');
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('--- [QUAKE_MAIN] WidgetsBinding initialized ---');
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('--- [QUAKE_MAIN] Firebase initialized ---');

    // Initialize Mobile Ads SDK
    MobileAds.instance.initialize();
    debugPrint('--- [QUAKE_MAIN] MobileAds initialized ---');
    
    // Register background handler BEFORE any other initialization
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('--- [QUAKE_MAIN] Background handler registered ---');

    await SeismographBackgroundService.initialize();
    await BackgroundService.initialize();
    debugPrint('--- [QUAKE_MAIN] BackgroundService initialized ---');

    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
    debugPrint('--- [QUAKE_MAIN] LocalNotifications initialized ---');

    final String? launchPayload =
        notificationAppLaunchDetails?.notificationResponse?.payload;
    if (launchPayload != null) {
      try {
        final Map<String, dynamic> payloadData = jsonDecode(launchPayload);
        final earthquakeData = payloadData['earthquake'];
        if (earthquakeData != null) {
          final String id = earthquakeData['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            NavigationService.initialRoute = '/details/${Uri.encodeComponent(id)}';
          }
        }
      } catch (e) {
        debugPrint('Error parsing notification launch payload: $e');
      }
    }

    const bool isTest = bool.fromEnvironment('IS_TEST_MODE');
    if (!isTest) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

      // Global Error Boundary UI
      ErrorWidget.builder = (FlutterErrorDetails details) {
        FirebaseCrashlytics.instance.recordFlutterError(details);
        return GlobalErrorView(errorDetails: details);
      };
    }

    debugPrint('--- [QUAKE_MAIN] Calling runApp ---');
    runApp(const ProviderScope(child: MyApp()));

  }, (error, stack) {
    debugPrint('--- [QUAKE_MAIN] runZonedGuarded ERROR: $error ---');
    FirebaseCrashlytics.instance.recordError(error, stack);
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final settings = ref.watch(settingsProvider);

    // Initialize shortcuts
    // We can use ref.listen to initialize once or just call it here (if it's idempotent)
    // ShortcutService.initialize needs a BuildContext, so we'll call it in a Builder or similar.
    
    return MaterialApp.router(
      routerConfig: router,
      title: 'QuakeTrack',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.isLoaded ? settings.themeMode : themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('tr'), // Turkish
        Locale('es'), // Spanish
      ],
      builder: (context, child) {
        // Initialize shortcuts once context is ready
        ShortcutService.initialize(context, ref);
        return child!;
      },
    );
  }
}
