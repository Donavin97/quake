import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserPreferences(String userId, Map<String, dynamic> preferences, {Position? position}) async {
    if (position != null) {
      preferences['location'] = GeoPoint(position.latitude, position.longitude);
    }
    await _firestore.collection('user_preferences').doc(userId).set(preferences, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserPreferences(String userId) async {
    final doc = await _firestore.collection('user_preferences').doc(userId).get();
    return doc.data();
  }

  Future<void> saveFCMToken(String token) async {
    await _firestore.collection('fcm_tokens').doc(token).set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}