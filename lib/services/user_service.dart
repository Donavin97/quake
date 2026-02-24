import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dart_geohash/dart_geohash.dart';
import '../models/user_preferences.dart';
import '../models/notification_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserPreferences(String userId, UserPreferences preferences, {Position? position, String? fcmToken}) async {
    final userRef = _firestore.collection('users').doc(userId);
    final Map<String, dynamic> dataToSet = {'preferences': preferences.toMap()};

    if (position != null) {
      final geohash = GeoHasher().encode(position.longitude, position.latitude);
      dataToSet['location'] = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'geohash': geohash,
      };
    }
    if (fcmToken != null) {
      dataToSet['fcmToken'] = fcmToken;
    }
    await userRef.set(dataToSet, SetOptions(merge: true));
  }

  Future<void> updateFCMToken(String userId, String fcmToken) async {
    await _firestore.collection('users').doc(userId).update({
      'fcmToken': fcmToken,
    });
  }

  Future<UserPreferences?> getUserPreferences(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data.containsKey('preferences')) {
        return UserPreferences.fromMap(data['preferences'] as Map<String, dynamic>);
      }
    }
    return null;
  }

  Future<void> addNotificationProfile(String userId, NotificationProfile profile) async {
    final userPreferences = await getUserPreferences(userId);
    if (userPreferences != null) {
      final updatedProfiles = List<NotificationProfile>.from(userPreferences.notificationProfiles);
      updatedProfiles.add(profile);
      final updatedPreferences = userPreferences.copyWith(
        notificationProfiles: updatedProfiles,
      );
      await saveUserPreferences(userId, updatedPreferences);
    } else {
      // Handle case where user preferences don't exist yet, create default with new profile
      final newPreferences = UserPreferences(
        notificationProfiles: [profile],
      );
      await saveUserPreferences(userId, newPreferences);
    }
  }

  Future<void> updateNotificationProfile(String userId, NotificationProfile profile) async {
    final userPreferences = await getUserPreferences(userId);
    if (userPreferences != null) {
      final updatedProfiles = userPreferences.notificationProfiles.map((p) {
        return p.id == profile.id ? profile : p;
      }).toList();
      final updatedPreferences = userPreferences.copyWith(
        notificationProfiles: updatedProfiles,
      );
      await saveUserPreferences(userId, updatedPreferences);
    }
  }

  Future<void> deleteNotificationProfile(String userId, String profileId) async {
    final userPreferences = await getUserPreferences(userId);
    if (userPreferences != null) {
      final updatedProfiles = userPreferences.notificationProfiles.where((p) => p.id != profileId).toList();
      final updatedPreferences = userPreferences.copyWith(
        notificationProfiles: updatedProfiles,
      );
      await saveUserPreferences(userId, updatedPreferences);
    }
  }

  Future<void> updateUserLocation(String userId, Position position) async {
    final geohash = GeoHasher().encode(position.longitude, position.latitude);
    await _firestore.collection('users').doc(userId).set({
      'location': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'geohash': geohash,
      }
    }, SetOptions(merge: true));
  }
}
