import 'package:cloud_firestore/cloud_firestore.dart';

class SeismicReading {
  final String id;
  final String userId;
  final double magnitude; // Combined acceleration vector
  final double x;
  final double y;
  final double z;
  final double latitude;
  final double longitude;
  final String geohash;
  final DateTime timestamp;

  SeismicReading({
    required this.id,
    required this.userId,
    required this.magnitude,
    required this.x,
    required this.y,
    required this.z,
    required this.latitude,
    required this.longitude,
    required this.geohash,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'magnitude': magnitude,
      'x': x,
      'y': y,
      'z': z,
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory SeismicReading.fromMap(String id, Map<String, dynamic> data) {
    return SeismicReading(
      id: id,
      userId: data['userId'] ?? '',
      magnitude: data['magnitude']?.toDouble() ?? 0.0,
      x: data['x']?.toDouble() ?? 0.0,
      y: data['y']?.toDouble() ?? 0.0,
      z: data['z']?.toDouble() ?? 0.0,
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      geohash: data['geohash'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
