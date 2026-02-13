
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  AuthService() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _setupUser(user);
      }
      notifyListeners();
    });
  }

  Future<void> _setupUser(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final doc = await userDoc.get();

    if (!doc.exists) {
      // New user, create a document for them
      userDoc.set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      // Failed to sign in with email and password
      rethrow;
    }
  }

  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      // Failed to create user with email and password
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      // Failed to sign in with Google
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      // Failed to sign out
      rethrow;
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      await currentUser?.verifyBeforeUpdateEmail(newEmail);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final uid = user.uid;

        // Delete user's preferences
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('preferences')
            .doc('settings')
            .delete();

        // Delete user document from 'users' collection
        await _firestore.collection('users').doc(uid).delete();

        // Delete user's felt reports
        final feltReports = await _firestore
            .collection('felt_reports')
            .where('userId', isEqualTo: uid)
            .get();
        final batch = _firestore.batch();
        for (final doc in feltReports.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        await user.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
