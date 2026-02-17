import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dart_geohash/dart_geohash.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserPreferences(String userId, Map<String, dynamic> preferences, {Position? position, String? fcmToken}) async {
    final userRef = _firestore.collection('users').doc(userId);
    final Map<String, dynamic> dataToSet = {'preferences': preferences};

    if (position != null) {
      final geohash = GeoHasher().encode(position.longitude, position.latitude);
      dataToSet['location'] = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'geohash': geohash,
      };
    }
    if (fcmToken != null) {
      dataToSet['fcmToken'] = fcmToken;
    }
    await userRef.set(dataToSet, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data()?['preferences'];
    }
    return null;
  }

  Future<void> updateUserLocation(String userId, Position position) async {
    final geohash = GeoHasher().encode(position.longitude, position.latitude);
    await _firestore.collection('users').doc(userId).set({
      'location': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'geohash': geohash,
      }
    }, SetOptions(merge: true));
  }
}
