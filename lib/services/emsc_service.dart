import '../models/earthquake.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmscService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Earthquake>> getEarthquakesStream() {
    return _firestore.collection('earthquakes').where('source', isEqualTo: 'emsc').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Earthquake.fromFirestore(doc)).toList();
    });
  }

  Future<List<Earthquake>> fetchEarthquakes() async {
    final snapshot = await _firestore.collection('earthquakes').where('source', isEqualTo: 'emsc').get();
    return snapshot.docs.map((doc) => Earthquake.fromFirestore(doc)).toList();
  }
}
