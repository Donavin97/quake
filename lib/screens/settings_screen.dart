
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _getAndStoreFCMToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      print('FCM Token: $fcmToken');
      // Store the token in Firestore
      await FirebaseFirestore.instance.collection('fcmTokens').doc(fcmToken).set({
        'token': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minimum Magnitude: ${settings.minMagnitude.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Slider(
                  value: settings.minMagnitude,
                  min: 0,
                  max: 10,
                  divisions: 100,
                  label: settings.minMagnitude.toStringAsFixed(1),
                  onChanged: (value) {
                    settings.setMinMagnitude(value);
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Time Window',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SegmentedButton<TimeWindow>(
                  segments: const [
                    ButtonSegment(
                      value: TimeWindow.day,
                      label: Text('1 Day'),
                      icon: Icon(Icons.today),
                    ),
                    ButtonSegment(
                      value: TimeWindow.week,
                      label: Text('7 Days'),
                      icon: Icon(Icons.calendar_view_week),
                    ),
                    ButtonSegment(
                      value: TimeWindow.month,
                      label: Text('30 Days'),
                      icon: Icon(Icons.calendar_month),
                    ),
                  ],
                  selected: {settings.timeWindow},
                  onSelectionChanged: (newSelection) {
                    settings.setTimeWindow(newSelection.first);
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _getAndStoreFCMToken,
                  child: const Text('Get and Store FCM Token'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
