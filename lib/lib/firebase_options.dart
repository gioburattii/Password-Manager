import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

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
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    authDomain: 'your-project.firebaseapp.com',
    projectId: 'your-project',
    storageBucket: 'your-project.appspot.com',
    messagingSenderId: '1234567890',
    appId: '1:1234567890:web:abc123def456',
    measurementId: 'G-XXXXXXXXXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:1234567890:android:abc123def456',
    messagingSenderId: '1234567890',
    projectId: 'your-project',
    storageBucket: 'your-project.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:1234567890:ios:abc123def456',
    messagingSenderId: '1234567890',
    projectId: 'your-project',
    storageBucket: 'your-project.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.example.yourApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:1234567890:macos:abc123def456',
    messagingSenderId: '1234567890',
    projectId: 'your-project',
    storageBucket: 'your-project.appspot.com',
    iosClientId: 'YOUR_MACOS_CLIENT_ID',
    iosBundleId: 'com.example.yourApp',
  );
}
