import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:async';

class DeviceBindingException implements Exception {
  final String message;
  final String? linkedEmail;
  final String? linkedUserId;

  DeviceBindingException(this.message, {this.linkedEmail, this.linkedUserId});

  @override
  String toString() => message;
}

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<DocumentSnapshot>? _lockoutSubscription;

  User? get currentUser => _auth.currentUser;

  AuthService() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _setupUser(user);
      } else {
        await _userSubscription?.cancel();
        _userSubscription = null;
        await _lockoutSubscription?.cancel();
        _lockoutSubscription = null;
      }
      notifyListeners();
    });
  }

  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return 'android_${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}_${androidInfo.hardware}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_device';
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }
    return 'unknown_device';
  }

  Future<void> unlinkCurrentDevice() async {
    final deviceId = await _getDeviceId();
    if (deviceId == 'unknown_device') return;
    await _firestore.collection('device_accounts').doc(deviceId).delete();
  }

  Future<void> _verifyDeviceBinding(User user) async {
    final deviceId = await _getDeviceId();
    if (deviceId == 'unknown_device') return;

    final deviceRef = _firestore.collection('device_accounts').doc(deviceId);
    final deviceDoc = await deviceRef.get();

    if (deviceDoc.exists) {
      final data = deviceDoc.data()!;
      final linkedEmail = (data['email'] as String?)?.toLowerCase();
      final linkedUserId = data['userId'] as String?;
      final currentEmail = user.email?.toLowerCase();
      
      if (linkedUserId == user.uid) {
        if (linkedEmail != currentEmail) {
          await deviceRef.update({'email': user.email});
        }
        return;
      }
      
      if (linkedEmail != null && linkedEmail != currentEmail) {
        await signOut();
        throw DeviceBindingException(
          'This device is currently linked to another account ($linkedEmail). To use your account ($currentEmail) here, you must first unlink the previous account.',
          linkedEmail: linkedEmail,
          linkedUserId: linkedUserId,
        );
      }
      
      if (linkedEmail == currentEmail) {
        await deviceRef.update({'userId': user.uid});
      }
    } else {
      await deviceRef.set({
        'email': user.email,
        'userId': user.uid,
        'linkedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _checkLockout(String email) async {
    final lockoutRef = _firestore.collection('login_lockouts').doc(email.toLowerCase().trim());
    final lockoutDoc = await lockoutRef.get();
    if (lockoutDoc.exists) {
      final data = lockoutDoc.data()!;
      final attempts = data['attempts'] as int? ?? 0;
      final isLocked = data['locked'] as bool? ?? false;
      final lastAttempt = (data['lastAttempt'] as Timestamp?)?.toDate();
      
      if (isLocked || attempts >= 3) {
        if (lastAttempt != null) {
          final now = DateTime.now();
          if (now.difference(lastAttempt).inMinutes >= 30) {
            await _resetLockout(email);
            return;
          }
        }
        throw 'This account has been locked due to too many failed login attempts. Please wait 30 minutes or contact support.';
      }
    }
  }

  Future<void> _handleFailedAttempt(String email) async {
    final lockoutRef = _firestore.collection('login_lockouts').doc(email.toLowerCase().trim());
    await lockoutRef.set({
      'attempts': FieldValue.increment(1),
      'lastAttempt': FieldValue.serverTimestamp(),
      'locked': false,
    }, SetOptions(merge: true));

    final updatedDoc = await lockoutRef.get();
    final attempts = updatedDoc.data()?['attempts'] as int? ?? 0;
    if (attempts >= 3) {
      await lockoutRef.update({'locked': true});
    }
  }

  Future<void> _resetLockout(String email) async {
    final lockoutRef = _firestore.collection('login_lockouts').doc(email.toLowerCase().trim());
    await lockoutRef.delete();
  }

  Future<void> forceSwitchDevice(String email, String password) async {
    await _checkLockout(email);
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        await _resetLockout(email);
        final deviceId = await _getDeviceId();
        if (deviceId != 'unknown_device') {
          await _firestore.collection('device_accounts').doc(deviceId).set({
            'email': user.email,
            'userId': user.uid,
            'linkedAt': FieldValue.serverTimestamp(),
            'switchedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        await _handleFailedAttempt(email);
      }
      rethrow;
    }
  }

  Future<void> forceSwitchDeviceWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    
    if (user != null) {
      final deviceId = await _getDeviceId();
      if (deviceId != 'unknown_device') {
        await _firestore.collection('device_accounts').doc(deviceId).set({
          'email': user.email,
          'userId': user.uid,
          'linkedAt': FieldValue.serverTimestamp(),
          'switchedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> _setupUser(User user) async {
    final deviceId = await _getDeviceId();
    final userDoc = _firestore.collection('users').doc(user.uid);
    
    await userDoc.set({
      'email': user.email,
      'lastDeviceId': deviceId,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _listenToUserChanges(user.uid, user.email);
  }

  void _listenToUserChanges(String uid, String? email) {
    _userSubscription?.cancel();
    _userSubscription = _firestore.collection('users').doc(uid).snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        final data = snapshot.data();
        final lastDeviceId = data?['lastDeviceId'] as String?;
        final currentDeviceId = await _getDeviceId();
        
        if (lastDeviceId != null && lastDeviceId != currentDeviceId) {
          debugPrint('Session invalidated: Logged in from another device.');
          await signOut();
        }
      }
    });

    if (email != null) {
      _lockoutSubscription?.cancel();
      _lockoutSubscription = _firestore.collection('login_lockouts').doc(email.toLowerCase().trim()).snapshots().listen((snapshot) async {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          if (data['locked'] == true) {
            debugPrint('Session invalidated: Account has been locked.');
            await signOut();
          }
        }
      });
    }
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    await _checkLockout(email);
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        await _resetLockout(email);
        await _verifyDeviceBinding(user);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        await _handleFailedAttempt(email);
        final lockoutDoc = await _firestore.collection('login_lockouts').doc(email.toLowerCase().trim()).get();
        final attempts = lockoutDoc.data()?['attempts'] as int? ?? 0;
        if (attempts >= 3) {
          throw 'Too many failed attempts. This account has been locked. Please wait 30 minutes or contact support.';
        }
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final deviceId = await _getDeviceId();
      if (deviceId != 'unknown_device') {
        final deviceDoc = await _firestore.collection('device_accounts').doc(deviceId).get();
        if (deviceDoc.exists) {
          final linkedEmail = (deviceDoc.data()?['email'] as String?)?.toLowerCase();
          final currentEmail = email.toLowerCase().trim();
          
          if (linkedEmail != null && linkedEmail != currentEmail) {
            throw DeviceBindingException(
              'This device is currently linked to another account ($linkedEmail). To register your new account ($email) here, you must first unlink the previous account.',
              linkedEmail: linkedEmail,
            );
          }
        }
      }

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
        await _verifyDeviceBinding(user);
      }
      return user;
    } on DeviceBindingException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      final user = userCredential.user;
      if (user != null) {
        await _verifyDeviceBinding(user);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _userSubscription?.cancel();
      _userSubscription = null;
      await _lockoutSubscription?.cancel();
      _lockoutSubscription = null;
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
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

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reauthenticateWithEmailAndPassword(String password) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      final email = user.email!;
      await _checkLockout(email);
      try {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        await _resetLockout(email);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          await _handleFailedAttempt(email);
          final lockoutDoc = await _firestore.collection('login_lockouts').doc(email.toLowerCase().trim()).get();
          final attempts = lockoutDoc.data()?['attempts'] as int? ?? 0;
          if (attempts >= 3) {
            await signOut();
            throw 'Too many failed attempts. This account has been locked. Please contact support.';
          }
        }
        rethrow;
      }
    }
  }

  Future<void> reauthenticateWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final uid = user.uid;
        await _firestore.collection('users').doc(uid).delete();
        await _firestore.collection('user_preferences').doc(uid).delete();
        await _firestore.collection('user_fcm_tokens').doc(uid).delete();
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
