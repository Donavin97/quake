import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_providers.dart';

part 'user_provider.freezed.dart';
part 'user_provider.g.dart';

@freezed
class UserState with _$UserState {
  const factory UserState({
    @Default(false) bool isSetupComplete,
    @Default(false) bool initialized,
  }) = _UserState;
}

@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  UserState build() {
    _init();
    return const UserState();
  }

  void _init() {
    final auth = ref.read(firebaseAuthProvider);
    auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadSetupStatus(user);
      } else {
        state = state.copyWith(isSetupComplete: false, initialized: true);
      }
    });
  }

  Future<void> _loadSetupStatus(User user) async {
    final firestore = ref.read(firebaseFirestoreProvider);
    final userDoc = firestore.collection('users').doc(user.uid);
    final doc = await userDoc.get();

    bool isSetupComplete = false;
    if (doc.exists && doc.data()!.containsKey('setupComplete')) {
      isSetupComplete = doc.data()!['setupComplete'] as bool;
    }
    
    state = state.copyWith(isSetupComplete: isSetupComplete, initialized: true);
  }

  Future<void> completeSetup() async {
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;
    if (user != null) {
      final firestore = ref.read(firebaseFirestoreProvider);
      final userDoc = firestore.collection('users').doc(user.uid);
      await userDoc.set({'setupComplete': true}, SetOptions(merge: true));
      state = state.copyWith(isSetupComplete: true);
    }
  }
}
