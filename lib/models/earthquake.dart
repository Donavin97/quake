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
  double? distance;

  Earthquake({
    required this.id,
    required this.magnitude,
    required this.place,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.source,
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
      source: EarthquakeSource.values.firstWhere((e) => e.toString() == 'EarthquakeSource.${data['source']}'),
    );
  }
}

class UsgsEarthquake extends Earthquake {
  UsgsEarthquake({
    required super.id,
    required super.magnitude,
    required super.place,
    required super.time,
    required super.latitude,
    required super.longitude,
  }) : super(source: EarthquakeSource.usgs);

  factory UsgsEarthquake.fromJson(Map<String, dynamic> json) {
    return UsgsEarthquake(
      id: json['id'],
      magnitude: json['properties']['mag']?.toDouble() ?? 0.0,
      place: json['properties']['place'] ?? 'Unknown',
      time: DateTime.fromMillisecondsSinceEpoch(json['properties']['time']),
      latitude: json['geometry']['coordinates'][1]?.toDouble() ?? 0.0,
      longitude: json['geometry']['coordinates'][0]?.toDouble() ?? 0.0,
    );
  }
}

class EmscEarthquake extends Earthquake {
  EmscEarthquake({
    required super.id,
    required super.magnitude,
    required super.place,
    required super.time,
    required super.latitude,
    required super.longitude,
  }) : super(source: EarthquakeSource.emsc);

  factory EmscEarthquake.fromJson(Map<String, dynamic> json) {
    return EmscEarthquake(
      id: json['id'],
      magnitude: json['properties']['mag']?.toDouble() ?? 0.0,
      place: json['properties']['flynn_region'] ?? 'Unknown',
      time: DateTime.parse(json['properties']['time']),
      latitude: json['geometry']['coordinates'][1]?.toDouble() ?? 0.0,
      longitude: json['geometry']['coordinates'][0]?.toDouble() ?? 0.0,
    );
  }
}
