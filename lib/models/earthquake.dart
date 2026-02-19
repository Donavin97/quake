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
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    EarthquakeSource sourceEnum;
    final sourceStr = (json['source'] as String? ?? '').toUpperCase();
    if (sourceStr == 'USGS') {
      sourceEnum = EarthquakeSource.usgs;
    } else if (sourceStr == 'EMSC') {
      sourceEnum = EarthquakeSource.emsc;
    } else if (sourceStr == 'SEC') {
      sourceEnum = EarthquakeSource.sec;
    } else {
      sourceEnum = EarthquakeSource.usgs; // Default value
    }

    return Earthquake(
      id: json['id'] ?? '',
      magnitude: parseDouble(json['magnitude']),
      place: json['place'] ?? 'Unknown',
      time: DateTime.fromMillisecondsSinceEpoch(json['time'] ?? 0),
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      depth: parseDouble(json['depth']),
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
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final coords = json['geometry']['coordinates'] as List<dynamic>;
    final depthValue = coords.length > 2 ? coords[2] : 0.0;

    return Earthquake(
      id: json['id'],
      magnitude: parseDouble(json['properties']['mag']),
      place: json['properties']['place'] ?? 'Unknown',
      time: DateTime.fromMillisecondsSinceEpoch(json['properties']['time']),
      latitude: parseDouble(coords[1]),
      longitude: parseDouble(coords[0]),
      depth: parseDouble(depthValue),
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

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final coords = json['geometry']['coordinates'] as List<dynamic>;
    final depthInCoords = coords.length > 2 ? coords[2] : null;
    final depthInProps = json['properties']['depth'];

    return Earthquake(
      id: json['id'],
      magnitude: parseDouble(json['properties']['mag']),
      place: json['properties']['flynn_region'] ?? 'Unknown',
      time: parsedTime,
      latitude: parseDouble(coords[1]),
      longitude: parseDouble(coords[0]),
      depth: parseDouble(depthInProps ?? depthInCoords),
      source: EarthquakeSource.emsc,
      provider: 'EMSC',
    );
  }

  factory Earthquake.fromSecJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final mag = parseDouble(json['mag']);
    return Earthquake(
      id: json['eventID'],
      magnitude: double.parse(mag.toStringAsFixed(2)),
      place: json['region'] ?? 'Unknown',
      time: DateTime.parse(json['otime']).toLocal(),
      latitude: parseDouble(json['lat']),
      longitude: parseDouble(json['lon']),
      depth: parseDouble(json['depth']),
      source: EarthquakeSource.sec,
      provider: 'SEC',
    );
  }

}
