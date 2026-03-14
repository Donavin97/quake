import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/seismic_reading.dart';

class SeismographBackgroundService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'seismograph_channel',
      'Community Seismograph',
      description: 'Background monitoring for seismic activity',
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'seismograph_channel',
        initialNotificationTitle: 'Community Seismograph',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static void start() {
    FlutterBackgroundService().startService();
  }

  static void stop() {
    FlutterBackgroundService().invoke('stopService');
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final Battery battery = Battery();
    final AudioPlayer player = AudioPlayer();
    
    StreamSubscription<UserAccelerometerEvent>? accelerometerSubscription;
    StreamSubscription<BatteryState>? batterySubscription;
    Timer? settleTimer;
    
    bool isCharging = false;
    bool isRecording = false;
    bool isSettling = false;
    String? currentUserId;
    DateTime? lastUploadTime;
    const Duration uploadCooldown = Duration(seconds: 10);
    const Duration settleDuration = Duration(seconds: 30);
    const double magnitudeThreshold = 0.1;

    void sendUpdate(String status) {
      service.invoke('update', {
        'isRecording': isRecording,
        'isSettling': isSettling,
        'isCharging': isCharging,
        'status': status,
        'lastHeartbeat': DateTime.now().toIso8601String(),
      });
    }

    void updateNotification(String status) {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Community Seismograph",
          content: status,
        );
      }
      sendUpdate(status);
    }

    updateNotification("Starting service...");

    // Async dependency initialization
    Future<void> initDependencies() async {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        
        final prefs = await SharedPreferences.getInstance();
        currentUserId = prefs.getString('bg_user_id');
        
        debugPrint('Background Seismograph: Dependencies ready. User: $currentUserId');
        if (currentUserId == null) {
          updateNotification("Paused - No user identified");
        }
      } catch (e) {
        debugPrint('Background Seismograph: Init error: $e');
        updateNotification("Error during initialization");
      }
    }
    
    initDependencies();

    Future<void> playStartSound() async {
      try {
        await player.setAudioSource(AudioSource.uri(
          Uri.parse("android.resource://com.liebgott.eqtrack/raw/recording")
        ));
        await player.play();
      } catch (e) {
        debugPrint('Background Seismograph: Audio error: $e');
      }
    }

    Future<void> uploadReading(UserAccelerometerEvent event, double magnitude) async {
      if (currentUserId == null || (lastUploadTime != null && DateTime.now().difference(lastUploadTime!) < uploadCooldown)) {
        return;
      }

      try {
        Position? position = await Geolocator.getLastKnownPosition();
        position ??= await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 5))
          ).timeout(const Duration(seconds: 6));
        
        lastUploadTime = DateTime.now();
        final geohash = GeoHasher().encode(position.longitude, position.latitude);
        
        final reading = SeismicReading(
          id: '', 
          userId: currentUserId!,
          magnitude: magnitude,
          x: event.x,
          y: event.y,
          z: event.z,
          latitude: position.latitude,
          longitude: position.longitude,
          geohash: geohash,
          timestamp: DateTime.now(),
        );

        await FirebaseFirestore.instance.collection('community_readings').add(reading.toMap());
      } catch (e) {
        debugPrint('Background Seismograph: Upload failed: $e');
      }
    }

    void stopAccelerometer() {
      accelerometerSubscription?.cancel();
      accelerometerSubscription = null;
      isRecording = false;
      updateNotification("Paused - Connect to charger");
    }

    void startAccelerometer() {
      if (isRecording || currentUserId == null) return;
      
      isRecording = true;
      isSettling = false;
      updateNotification("Active - Monitoring tremors");
      playStartSound();

      accelerometerSubscription = userAccelerometerEventStream().listen((event) {
        final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        if (magnitude > magnitudeThreshold) {
          uploadReading(event, magnitude);
        }
      });
    }

    void startSettleTimer() {
      if (isSettling || isRecording) return;
      isSettling = true;
      updateNotification("Settling - Stabilizing device...");
      
      settleTimer?.cancel();
      settleTimer = Timer(settleDuration, () {
        if (isCharging) {
          startAccelerometer();
        } else {
          isSettling = false;
          updateNotification("Paused - Disconnected");
        }
      });
    }

    void updateRecordingState() {
      if (isCharging) {
        if (!isRecording && !isSettling) {
          startSettleTimer();
        }
      } else {
        settleTimer?.cancel();
        isSettling = false;
        if (isRecording) {
          stopAccelerometer();
        } else {
          updateNotification("Paused - Connect to charger");
        }
      }
    }

    // Battery State logic with more robust checks
    void checkInitialBattery() async {
      try {
        final state = await battery.batteryState;
        isCharging = state == BatteryState.charging || state == BatteryState.full;
        debugPrint('Background Seismograph: Initial battery state: $state');
        updateRecordingState();
      } catch (e) {
        debugPrint('Background Seismograph: Battery check error: $e');
      }
    }
    
    checkInitialBattery();

    batterySubscription = battery.onBatteryStateChanged.listen((state) {
      isCharging = state == BatteryState.charging || state == BatteryState.full;
      debugPrint('Background Seismograph: Battery state change: $state');
      updateRecordingState();
    });

    service.on('stopService').listen((event) {
      batterySubscription?.cancel();
      accelerometerSubscription?.cancel();
      settleTimer?.cancel();
      player.dispose();
      service.stopSelf();
    });
  }
}
