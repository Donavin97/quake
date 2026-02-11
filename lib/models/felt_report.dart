import 'package:cloud_firestore/cloud_firestore.dart';

class FeltReport {
  final String earthquakeId;
  final String userId;
  final Timestamp timestamp;
  final GeoPoint location;

  FeltReport({
    required this.earthquakeId,
    required this.userId,
    required this.timestamp,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'earthquakeId': earthquakeId,
      'userId': userId,
      'timestamp': timestamp,
      'location': location,
    };
  }

  static FeltReport fromMap(Map<String, dynamic> map) {
    return FeltReport(
      earthquakeId: map['earthquakeId'],
      userId: map['userId'],
      timestamp: map['timestamp'],
      location: map['location'],
    );
  }
}
