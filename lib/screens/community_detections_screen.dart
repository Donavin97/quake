import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/seismic_reading.dart';
import '../providers/service_providers.dart';

class CommunityDetectionsScreen extends ConsumerWidget {
  const CommunityDetectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final firestore = ref.watch(firebaseFirestoreProvider);
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Contributions')),
        body: const Center(child: Text('Please sign in to view your contributions.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contributions'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('community_readings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sensors_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No detections recorded yet.'),
                  const SizedBox(height: 8),
                  const Text(
                    'Make sure the Community Seismograph is enabled\nand your phone is charging on a stable surface.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final reading = SeismicReading.fromMap(
                docs[index].id,
                docs[index].data() as Map<String, dynamic>,
              );

              return FutureBuilder<QuerySnapshot>(
                future: firestore
                    .collection('community_alerts')
                    .where('geohashPrefix', isEqualTo: reading.geohash.substring(0, 4))
                    .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(reading.timestamp.subtract(const Duration(minutes: 5))))
                    .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(reading.timestamp.add(const Duration(minutes: 5))))
                    .limit(1)
                    .get(),
                builder: (context, alertSnapshot) {
                  final hasAlert = alertSnapshot.hasData && alertSnapshot.data!.docs.isNotEmpty;
                  String? alertPlace;
                  int? userCount;
                  
                  if (hasAlert) {
                    final alertData = alertSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                    alertPlace = alertData['place'];
                    userCount = alertData['userCount'];
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getMagnitudeColor(reading.magnitude),
                      child: Icon(
                        hasAlert ? Icons.verified_user : Icons.vibration,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      hasAlert && alertPlace != null
                          ? alertPlace
                          : 'Magnitude: ${reading.magnitude.toStringAsFixed(3)} m/s²',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy - HH:mm:ss').format(reading.timestamp),
                        ),
                        if (hasAlert)
                          Text(
                            'Confirmed by $userCount+ users',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showReadingDetails(context, reading, hasAlert ? alertPlace : null, userCount),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _getMagnitudeColor(double magnitude) {
    if (magnitude > 1.0) return Colors.red;
    if (magnitude > 0.5) return Colors.orange;
    return Colors.blue;
  }

  void _showReadingDetails(BuildContext context, SeismicReading reading, String? alertPlace, int? userCount) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Detection Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (alertPlace != null) ...[
                  const Spacer(),
                  const Icon(Icons.verified, color: Colors.green),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (alertPlace != null)
              _detailRow('Confirmed Place', alertPlace),
            if (userCount != null)
              _detailRow('Total Contributors', userCount.toString()),
            _detailRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss').format(reading.timestamp)),
            _detailRow('Intensity', '${reading.magnitude.toStringAsFixed(4)} m/s²'),
            _detailRow('X-axis', reading.x.toStringAsFixed(4)),
            _detailRow('Y-axis', reading.y.toStringAsFixed(4)),
            _detailRow('Z-axis', reading.z.toStringAsFixed(4)),
            _detailRow('Location', '${reading.latitude.toStringAsFixed(4)}, ${reading.longitude.toStringAsFixed(4)}'),
            const SizedBox(height: 16),
            Text(
              alertPlace != null
                  ? 'Your device successfully contributed to a regional seismic detection with $userCount other users.'
                  : 'These readings help our network detect regional seismic events by correlating data from multiple devices.',
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
