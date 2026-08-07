import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'bitzlatoview-mobile',
    storageBucket: 'bitzlatoview-mobile.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:YOUR_PROJECT_NUMBER:ios:YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'bitzlatoview-mobile',
    storageBucket: 'bitzlatoview-mobile.appspot.com',
    iosBundleId: 'com.bitzlatoview.bitzlatoviewMobile',
  );
}
