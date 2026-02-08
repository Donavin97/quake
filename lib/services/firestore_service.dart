
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  late FirebaseFirestore _db;

  Future<void> init() async {
    _db = FirebaseFirestore.instance;
  }

  Future<void> saveUserPreferences(String fcmToken, double minMagnitude) async {
    await _db.collection('user_preferences').doc(fcmToken).set({
      'fcm_token': fcmToken,
      'min_magnitude': minMagnitude,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
