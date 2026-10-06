// File generated manually from android/app/google-services.json
// Project: emrullah-b3836

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
        throw UnsupportedError(
          'DefaultFirebaseOptions iOS için yapılandırılmadı. '
          'GoogleService-Info.plist ekleyin.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions macOS için yapılandırılmadı.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions Linux için yapılandırılmadı.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions bu platform için yapılandırılmadı.',
        );
    }
  }

  // Android — google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtSiS2dCCjsQkd901TkJBI1ejtACU8deM',
    appId: '1:1089075260680:android:7060e959fddbd55660d0bd',
    messagingSenderId: '1089075260680',
    projectId: 'deneyap-8666b',
    storageBucket: 'deneyap-8666b.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCtSiS2dCCjsQkd901TkJBI1ejtACU8deM',
    appId: '1:1089075260680:android:7060e959fddbd55660d0bd',
    messagingSenderId: '1089075260680',
    projectId: 'deneyap-8666b',
    authDomain: 'deneyap-8666b.firebaseapp.com',
    storageBucket: 'deneyap-8666b.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCtSiS2dCCjsQkd901TkJBI1ejtACU8deM',
    appId: '1:1089075260680:android:7060e959fddbd55660d0bd',
    messagingSenderId: '1089075260680',
    projectId: 'deneyap-8666b',
    storageBucket: 'deneyap-8666b.firebasestorage.app',
    authDomain: 'deneyap-8666b.firebaseapp.com',
  );
}
