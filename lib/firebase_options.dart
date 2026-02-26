import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
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
        throw UnsupportedError('Windows config not setup in .env example'); 
      case TargetPlatform.linux:
        throw UnsupportedError('Linux config not setup');
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static FirebaseOptions web = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_WEB_API_KEY']!,
    appId: dotenv.env['FIREBASE_WEB_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_WEB_PROJECT_ID']!,
    authDomain: dotenv.env['FIREBASE_WEB_AUTH_DOMAIN'],
    storageBucket: dotenv.env['FIREBASE_WEB_STORAGE_BUCKET'],
    measurementId: dotenv.env['FIREBASE_WEB_MEASUREMENT_ID'],
  );

  static FirebaseOptions android = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_ANDROID_API_KEY']!,
    appId: dotenv.env['FIREBASE_ANDROID_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID']!, // Usually same as web
    projectId: dotenv.env['FIREBASE_WEB_PROJECT_ID']!, // Usually same as web
    storageBucket: dotenv.env['FIREBASE_WEB_STORAGE_BUCKET'], // Usually same as web
  );

  static FirebaseOptions ios = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_IOS_API_KEY']!,
    appId: dotenv.env['FIREBASE_IOS_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_WEB_PROJECT_ID']!,
    storageBucket: dotenv.env['FIREBASE_WEB_STORAGE_BUCKET'],
    iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'],
  );
  
  // Reuse iOS for macOS if config is identical
  static FirebaseOptions macos = ios;
}