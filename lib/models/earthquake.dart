import 'package:hive/hive.dart';

part 'earthquake.g.dart';

@HiveType(typeId: 1)
enum EarthquakeSource {
  @HiveField(0)
  usgs,
  @HiveField(1)
  emsc,
  @HiveField(2)
  sec,
}

@HiveType(typeId: 0)
class Earthquake extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double magnitude;

  @HiveField(2)
  String place;

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

  @HiveField(9)
  final double depth;

  Earthquake({
    required this.id,
    required this.magnitude,
    required this.place,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.source,
    required this.provider,
    required this.depth,
    this.distance,
  });

  factory Earthquake.fromJson(Map<String, dynamic> json) {
    EarthquakeSource sourceEnum;
    if (json['source'] == 'USGS') {
      sourceEnum = EarthquakeSource.usgs;
    } else if (json['source'] == 'EMSC') {
      sourceEnum = EarthquakeSource.emsc;
    } else if (json['source'] == 'SEC') {
      sourceEnum = EarthquakeSource.sec;
    } else {
      sourceEnum = EarthquakeSource.usgs; // Default value
    }

    return Earthquake(
      id: json['id'] ?? '',
      magnitude: json['magnitude']?.toDouble() ?? 0.0,
      place: json['place'] ?? 'Unknown',
      time: DateTime.fromMillisecondsSinceEpoch(json['time'] ?? 0),
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      depth: json['depth']?.toDouble() ?? 0.0,
      source: sourceEnum,
      provider: json['source'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'magnitude': magnitude,
        'place': place,
        'time': time.millisecondsSinceEpoch,
        'latitude': latitude,
        'longitude': longitude,
        'depth': depth,
        'source': source.toString().split('.').last,
        'provider': provider,
      };

  factory Earthquake.fromUsgsJson(Map<String, dynamic> json) {
    return Earthquake(
      id: json['id'],
      magnitude: json['properties']['mag']?.toDouble() ?? 0.0,
      place: json['properties']['place'] ?? 'Unknown',
      time: DateTime.fromMillisecondsSinceEpoch(json['properties']['time']),
      latitude: json['geometry']['coordinates'][1]?.toDouble() ?? 0.0,
      longitude: json['geometry']['coordinates'][0]?.toDouble() ?? 0.0,
      depth: json['geometry']['coordinates'][2]?.toDouble() ?? 0.0,
      source: EarthquakeSource.usgs,
      provider: 'USGS',
    );
  }

  factory Earthquake.fromEmscJson(Map<String, dynamic> json) {
    final timeStr = json['properties']['time'];
    DateTime parsedTime;
    try {
      parsedTime = DateTime.parse(timeStr).toLocal();
    } catch (e) {
      parsedTime = DateTime.now();
    }

    return Earthquake(
      id: json['id'],
      magnitude: json['properties']['mag']?.toDouble() ?? 0.0,
      place: json['properties']['flynn_region'] ?? 'Unknown',
      time: parsedTime,
      latitude: json['geometry']['coordinates'][1]?.toDouble() ?? 0.0,
      longitude: json['geometry']['coordinates'][0]?.toDouble() ?? 0.0,
      depth: json['properties']['depth']?.toDouble() ?? 0.0,
      source: EarthquakeSource.emsc,
      provider: 'EMSC',
    );
  }

  factory Earthquake.fromSecJson(Map<String, dynamic> json) {
    final mag = (json['mag'] as num?)?.toDouble() ?? 0.0;
    return Earthquake(
      id: json['eventID'],
      magnitude: double.parse(mag.toStringAsFixed(2)),
      place: json['region'] ?? 'Unknown',
      time: DateTime.parse(json['otime']).toLocal(),
      latitude: (json['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['lon'] as num?)?.toDouble() ?? 0.0,
      depth: (json['depth'] as num?)?.toDouble() ?? 0.0,
      source: EarthquakeSource.sec,
      provider: 'SEC',
    );
  }

}
