import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCAhoSDQFBqrDvrcauinnOcs6mGrze-3B4',
    appId: '1:155808615108:android:8a5a5295c39dc30a9c9791',
    messagingSenderId: '155808615108',
    projectId: 'fitness-factor',
    storageBucket: 'fitness-factor.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCAhoSDQFBqrDvrcauinnOcs6mGrze-3B4',
    appId: '1:155808615108:android:8a5a5295c39dc30a9c9791',
    messagingSenderId: '155808615108',
    projectId: 'fitness-factor',
    storageBucket: 'fitness-factor.firebasestorage.app',
    iosBundleId: 'com.example.fitnessFactor',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCAhoSDQFBqrDvrcauinnOcs6mGrze-3B4',
    appId: '1:155808615108:android:8a5a5295c39dc30a9c9791',
    messagingSenderId: '155808615108',
    projectId: 'fitness-factor',
    storageBucket: 'fitness-factor.firebasestorage.app',
  );
}
