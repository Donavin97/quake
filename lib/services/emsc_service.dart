import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/earthquake.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmscService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Earthquake>> getEarthquakesStream() {
    return _firestore.collection('earthquakes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Earthquake.fromFirestore(doc)).toList();
    });
  }

  Future<List<Earthquake>> fetchEarthquakes() async {
    final snapshot = await _firestore.collection('earthquakes').get();
    return snapshot.docs.map((doc) => Earthquake.fromFirestore(doc)).toList();
  }
}
