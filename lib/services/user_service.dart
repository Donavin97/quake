import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserPreferences(String userId, Map<String, dynamic> preferences, {Position? position}) async {
    final userRef = _firestore.collection('users').doc(userId);
    if (position != null) {
      await userRef.set({
        'preferences': preferences,
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        }
      }, SetOptions(merge: true));
    } else {
      await userRef.set({'preferences': preferences}, SetOptions(merge: true));
    }
  }

  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data()?['preferences'];
    }
    return null;
  }

  Future<void> updateUserLocation(String userId, Position position) async {
    await _firestore.collection('users').doc(userId).set({
      'location': {
        'latitude': position.latitude,
        'longitude': position.longitude,
      }
    }, SetOptions(merge: true));
  }
}
