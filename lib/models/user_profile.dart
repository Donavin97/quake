class UserProfile {
  final String uid;
  final String email;
  final String displayName;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'],
      email: data['email'],
      displayName: data['displayName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
    };
  }
}
