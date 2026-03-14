import 'package:cloud_firestore/cloud_firestore.dart';

enum SafetyStatus { safe, unsafe, notReported }

class CircleMember {
  final String uid;
  final String email;
  final String displayName;
  final SafetyStatus status;
  final String? lastEarthquakeId;
  final DateTime? lastStatusUpdate;
  final double? latitude;
  final double? longitude;

  CircleMember({
    required this.uid,
    required this.email,
    required this.displayName,
    this.status = SafetyStatus.notReported,
    this.lastEarthquakeId,
    this.lastStatusUpdate,
    this.latitude,
    this.longitude,
  });

  factory CircleMember.fromMap(Map<String, dynamic> data) {
    return CircleMember(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      status: SafetyStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'notReported'),
        orElse: () => SafetyStatus.notReported,
      ),
      lastEarthquakeId: data['lastEarthquakeId'],
      lastStatusUpdate: data['lastStatusUpdate'] != null
          ? (data['lastStatusUpdate'] as Timestamp).toDate()
          : null,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'status': status.name,
      'lastEarthquakeId': lastEarthquakeId,
      'lastStatusUpdate': lastStatusUpdate != null ? Timestamp.fromDate(lastStatusUpdate!) : null,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  CircleMember copyWith({
    SafetyStatus? status,
    String? lastEarthquakeId,
    DateTime? lastStatusUpdate,
    double? latitude,
    double? longitude,
  }) {
    return CircleMember(
      uid: uid,
      email: email,
      displayName: displayName,
      status: status ?? this.status,
      lastEarthquakeId: lastEarthquakeId ?? this.lastEarthquakeId,
      lastStatusUpdate: lastStatusUpdate ?? this.lastStatusUpdate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
