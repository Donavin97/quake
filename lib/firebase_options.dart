
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCluBzRD9X29D9fammZIzuWzEeI7QH8CS0',
    appId: '1:205624709309:web:45806b2dd69f30e98c67d4',
    messagingSenderId: '205624709309',
    projectId: 'eqapp-56196',
    authDomain: 'eqapp-56196.firebaseapp.com',
    storageBucket: 'eqapp-56196.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCluBzRD9X29D9fammZIzuWzEeI7QH8CS0',
    appId: '1:205624709309:android:45806b2dd69f30e98c67d4',
    messagingSenderId: '205624709309',
    projectId: 'eqapp-56196',
    storageBucket: 'eqapp-56196.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCluBzRD9X29D9fammZIzuWzEeI7QH8CS0',
    appId: '1:205624709309:ios:45806b2dd69f30e98c67d4',
    messagingSenderId: '205624709309',
    projectId: 'eqapp-56196',
    storageBucket: 'eqapp-56196.appspot.com',
    iosBundleId: 'com.example.myapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCluBzRD9X29D9fammZIzuWzEeI7QH8CS0',
    appId: '1:205624709309:ios:45806b2dd69f30e98c67d4',
    messagingSenderId: '205624709309',
    projectId: 'eqapp-56196',
    storageBucket: 'eqapp-56196.appspot.com',
    iosBundleId: 'com.example.myapp',
  );
}
