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
    apiKey: 'AIzaSyAlamv3YVgD9gC0TtVHWdEMMrsVoBbFsGY',
    appId: '1:586775658888:android:3a29812f5be59193fd3a3d',
    messagingSenderId: '586775658888',
    projectId: 'emrullah-b3836',
    storageBucket: 'emrullah-b3836.firebasestorage.app',
  );

  // Web (Firebase Console: ikmalkısım - 1:586775658888:web:d732aec658d7f347fd3a3d)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDVCaU76z0TkQ48HzpMLhXJIhitcrCpYY4',
    appId: '1:586775658888:web:d732aec658d7f347fd3a3d',
    messagingSenderId: '586775658888',
    projectId: 'emrullah-b3836',
    authDomain: 'emrullah-b3836.firebaseapp.com',
    storageBucket: 'emrullah-b3836.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAlamv3YVgD9gC0TtVHWdEMMrsVoBbFsGY',
    appId: '1:586775658888:android:3a29812f5be59193fd3a3d',
    messagingSenderId: '586775658888',
    projectId: 'emrullah-b3836',
    storageBucket: 'emrullah-b3836.firebasestorage.app',
    authDomain: 'emrullah-b3836.firebaseapp.com',
  );
}
