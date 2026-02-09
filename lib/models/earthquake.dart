
class Earthquake {
  final String id;
  final double magnitude;
  final String place;
  final DateTime time;
  final double latitude;
  final double longitude;
  double? distance;

  Earthquake({
    required this.id,
    required this.magnitude,
    required this.place,
    required this.time,
    required this.latitude,
    required this.longitude,
    this.distance,
  });

  factory Earthquake.fromJson(Map<String, dynamic> json) {
    return Earthquake(
      id: json['id'],
      magnitude: json['properties']['mag']?.toDouble() ?? 0.0,
      place: json['properties']['place'] ?? 'Unknown',
      time: DateTime.fromMillisecondsSinceEpoch(json['properties']['time']),
      latitude: json['geometry']['coordinates'][1]?.toDouble() ?? 0.0,
      longitude: json['geometry']['coordinates'][0]?.toDouble() ?? 0.0,
    );
  }
}
