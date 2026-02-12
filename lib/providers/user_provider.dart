import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSetupComplete = false;
  bool get isSetupComplete => _isSetupComplete;

  UserProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadSetupStatus(user);
      } else {
        _isSetupComplete = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadSetupStatus(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final doc = await userDoc.get();

    if (doc.exists && doc.data()!.containsKey('setupComplete')) {
      _isSetupComplete = doc.data()!['setupComplete'] as bool;
    } else {
      _isSetupComplete = false;
    }
    notifyListeners();
  }

  Future<void> completeSetup() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = _firestore.collection('users').doc(user.uid);
      await userDoc.update({'setupComplete': true});
      _isSetupComplete = true;
      notifyListeners();
    }
  }
}
