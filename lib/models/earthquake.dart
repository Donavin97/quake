import 'package:hive/hive.dart';

part 'earthquake.g.dart';

@HiveType(typeId: 1)
enum EarthquakeSource {
  @HiveField(0)
  usgs,
  @HiveField(1)
  emsc,
}

@HiveType(typeId: 0)
class Earthquake extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double magnitude;

  @HiveField(2)
  final String place;

  @HiveField(3)
  final DateTime time;

  @HiveField(4)
  final double latitude;

  @HiveField(5)
  final double longitude;

  @HiveField(6)
  final EarthquakeSource source;

  @HiveField(7)
  final String provider;

  @HiveField(8)
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

  factory Earthquake.fromUsgsJson(Map<String, dynamic> json) {
    return Earthquake(
      id: json['id'],
      magnitude: json['properties']['mag']?.toDouble() ?? 0.0,
      place: json['properties']['place'] ?? 'Unknown',
      time: DateTime.fromMillisecondsSinceEpoch(json['properties']['time']),
      latitude: json['geometry']['coordinates'][1]?.toDouble() ?? 0.0,
      longitude: json['geometry']['coordinates'][0]?.toDouble() ?? 0.0,
      source: EarthquakeSource.usgs,
      provider: 'USGS',
    );
  }

  factory Earthquake.fromEmscJson(Map<String, dynamic> json) {
    return Earthquake(
      id: json['id'],
      magnitude: json['properties']['mag']?.toDouble() ?? 0.0,
      place: json['properties']['flynn_region'] ?? 'Unknown',
      time: DateTime.parse(json['properties']['time']).toLocal(),
      latitude: json['geometry']['coordinates'][1]?.toDouble() ?? 0.0,
      longitude: json['geometry']['coordinates'][0]?.toDouble() ?? 0.0,
      source: EarthquakeSource.emsc,
      provider: 'EMSC',
    );
  }
}
