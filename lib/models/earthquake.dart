import 'package:cloud_firestore/cloud_firestore.dart';

enum EarthquakeSource {
  usgs,
  emsc,
}

class Earthquake {
  final String id;
  final double magnitude;
  final String place;
  final DateTime time;
  final double latitude;
  final double longitude;
  final EarthquakeSource source;
  final String provider;
  double? distance;

  Earthquake({
    required this.id,
    required this.magnitude,
    required this.place,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.source,
    required this.provider,
    this.distance,
  });

  factory Earthquake.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Earthquake(
      id: doc.id,
      magnitude: data['magnitude']?.toDouble() ?? 0.0,
      place: data['place'] ?? 'Unknown',
      time: (data['time'] as Timestamp).toDate(),
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      source: EarthquakeSource.values.firstWhere((e) => e.toString().toLowerCase() == 'EarthquakeSource.${data['source']}'.toLowerCase()),
      provider: data['source'] ?? 'usgs',
    );
  }
}
