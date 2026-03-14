import 'package:cloud_firestore/cloud_firestore.dart';
import 'circle_member.dart';

class SafetyCircle {
  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final List<CircleMember> members;
  final DateTime createdAt;

  SafetyCircle({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.members,
    required this.createdAt,
  });

  factory SafetyCircle.fromMap(String id, Map<String, dynamic> data) {
    return SafetyCircle(
      id: id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      members: (data['members'] as List<dynamic>? ?? [])
          .map((m) => CircleMember.fromMap(m as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'inviteCode': inviteCode,
      'members': members.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
