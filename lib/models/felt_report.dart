import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FeltReport {
  final String earthquakeId;
  final String userId;
  final Timestamp timestamp;
  final GeoPoint location;
  final int intensity; // MMI Level (1-10)

  FeltReport({
    required this.earthquakeId,
    required this.userId,
    required this.timestamp,
    required this.location,
    required this.intensity,
  });

  Map<String, dynamic> toMap() {
    return {
      'earthquakeId': earthquakeId,
      'userId': userId,
      'timestamp': timestamp,
      'location': location,
      'intensity': intensity,
    };
  }

  static FeltReport fromMap(Map<String, dynamic> map) {
    return FeltReport(
      earthquakeId: map['earthquakeId'],
      userId: map['userId'],
      timestamp: map['timestamp'],
      location: map['location'],
      intensity: map['intensity'] ?? 1,
    );
  }

  static String getIntensityDescription(int level) {
    switch (level) {
      case 1: return 'Not Felt';
      case 2: return 'Weak';
      case 3: return 'Weak';
      case 4: return 'Light';
      case 5: return 'Moderate';
      case 6: return 'Strong';
      case 7: return 'Very Strong';
      case 8: return 'Severe';
      case 9: return 'Violent';
      case 10: return 'Extreme';
      default: return 'Unknown';
    }
  }

  static Color getIntensityColor(int level) {
    switch (level) {
      case 1: return Colors.blue.shade100;
      case 2: return Colors.blue.shade300;
      case 3: return Colors.cyan.shade300;
      case 4: return Colors.green.shade300;
      case 5: return Colors.yellow.shade600;
      case 6: return Colors.orange.shade400;
      case 7: return Colors.orange.shade700;
      case 8: return Colors.red.shade400;
      case 9: return Colors.red.shade700;
      case 10: return Colors.red.shade900;
      default: return Colors.grey;
    }
  }
}
