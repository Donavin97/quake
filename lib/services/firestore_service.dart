
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  late FirebaseFirestore _db;

  Future<void> init() async {
    _db = FirebaseFirestore.instance;
  }

  // Add other Firestore methods here, like getting user preferences
}
