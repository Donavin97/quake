import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/circle.dart';
import '../models/circle_member.dart';

class CircleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<String> createCircle(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final inviteCode = _generateInviteCode();
    final circleRef = _firestore.collection('circles').doc();
    
    final member = CircleMember(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.email?.split('@')[0] ?? 'User',
    );

    final circle = SafetyCircle(
      id: circleRef.id,
      name: name,
      ownerId: user.uid,
      inviteCode: inviteCode,
      members: [member],
      createdAt: DateTime.now(),
    );

    await circleRef.set({
      ...circle.toMap(),
      'memberIds': [user.uid],
    });
    return inviteCode;
  }

  Future<void> joinCircle(String inviteCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final query = await _firestore
        .collection('circles')
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .get();

    if (query.docs.isEmpty) throw Exception('Invalid invite code');

    final circleDoc = query.docs.first;
    final circle = SafetyCircle.fromMap(circleDoc.id, circleDoc.data());

    if (circle.members.any((m) => m.uid == user.uid)) {
      throw Exception('Already a member of this circle');
    }

    final newMember = CircleMember(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.email?.split('@')[0] ?? 'User',
    );

    await circleDoc.reference.update({
      'members': FieldValue.arrayUnion([newMember.toMap()]),
      'memberIds': FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> leaveCircle(String circleId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final circleRef = _firestore.collection('circles').doc(circleId);
    final doc = await circleRef.get();
    if (!doc.exists) return;

    final circle = SafetyCircle.fromMap(doc.id, doc.data()!);
    final member = circle.members.firstWhere((m) => m.uid == user.uid);

    await circleRef.update({
      'members': FieldValue.arrayRemove([member.toMap()]),
      'memberIds': FieldValue.arrayRemove([user.uid]),
    });

    if (circle.ownerId == user.uid) {
      if (circle.members.length <= 1) {
        await circleRef.delete();
      } else {
        final newOwner = circle.members.firstWhere((m) => m.uid != user.uid);
        await circleRef.update({'ownerId': newOwner.uid});
      }
    }
  }

  Future<void> updateSafetyStatus(String circleId, SafetyStatus status, {String? earthquakeId, double? lat, double? lon}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final circleRef = _firestore.collection('circles').doc(circleId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(circleRef);
      if (!snapshot.exists) return;

      final circle = SafetyCircle.fromMap(snapshot.id, snapshot.data()!);
      final memberIndex = circle.members.indexWhere((m) => m.uid == user.uid);
      
      if (memberIndex == -1) return;

      final updatedMember = circle.members[memberIndex].copyWith(
        status: status,
        lastEarthquakeId: earthquakeId,
        lastStatusUpdate: DateTime.now(),
        latitude: lat,
        longitude: lon,
      );

      final updatedMembers = List<CircleMember>.from(circle.members);
      updatedMembers[memberIndex] = updatedMember;

      transaction.update(circleRef, {
        'members': updatedMembers.map((m) => m.toMap()).toList(),
      });
    });
  }

  Stream<List<SafetyCircle>> getMyCircles() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('circles')
        .where('memberIds', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SafetyCircle.fromMap(doc.id, doc.data()))
            .toList());
  }
}
