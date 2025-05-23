// lib/firebase_options.dart
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
    apiKey: 'AIzaSyCO97frRkfZ-JHJzDlQSdkQJ6jsyr3kKGs',
    appId: '1:872277255917:web:20c9af125b2d45fd278ee4',
    messagingSenderId: '872277255917',
    projectId: 'greenwatch-63622',
    authDomain: 'greenwatch-63622.firebaseapp.com',
    storageBucket: 'greenwatch-63622.firebasestorage.app',
    measurementId: 'G-02DBZ5CSR2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgAHigBWNpyXkU1V-4fgWQGb1-hDUxAO8',
    appId: '1:872277255917:android:f16c964f45e5ee96278ee4',
    messagingSenderId: '872277255917',
    projectId: 'greenwatch-63622',
    storageBucket: 'greenwatch-63622.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAGjyzxFi7p6tWhZV77xnTxUDWar6SrT9o',
    appId: '1:872277255917:ios:4ebe01130f6e4323278ee4',
    messagingSenderId: '872277255917',
    projectId: 'greenwatch-63622',
    storageBucket: 'greenwatch-63622.firebasestorage.app',
    iosBundleId: 'com.flutter.flutterApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAGjyzxFi7p6tWhZV77xnTxUDWar6SrT9o',
    appId: '1:872277255917:ios:4ebe01130f6e4323278ee4',
    messagingSenderId: '872277255917',
    projectId: 'greenwatch-63622',
    storageBucket: 'greenwatch-63622.firebasestorage.app',
    iosBundleId: 'com.flutter.flutterApp',
  );
}