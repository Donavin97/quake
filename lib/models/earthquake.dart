class Earthquake {
  final String id;
  final double magnitude;
  final String place;
  final DateTime time;
  final double longitude;
  final double latitude;
  final double depth;
  double? distanceFromUser;

  Earthquake({
    required this.id,
    required this.magnitude,
    required this.place,
    required this.time,
    required this.longitude,
    required this.latitude,
    required this.depth,
    this.distanceFromUser,
  });

  factory Earthquake.fromJson(Map<String, dynamic> json) {
    return Earthquake(
      id: json['id'],
      magnitude: (json['properties']['mag'] ?? 0).toDouble(),
      place: json['properties']['place'] ?? 'Unknown',
      time: DateTime.fromMillisecondsSinceEpoch(json['properties']['time']),
      longitude: json['geometry']['coordinates'][0].toDouble(),
      latitude: json['geometry']['coordinates'][1].toDouble(),
      depth: json['geometry']['coordinates'][2].toDouble(),
    );
  }
}
