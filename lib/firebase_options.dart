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
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCZ2blzS1eCmrAilkzJwprOE7KG0rdohZk',
    appId: '1:769860703778:android:2a664a9d8f926fcbafdc7b',
    messagingSenderId: '769860703778',
    projectId: 'bb-draft-app-2026',
    storageBucket: 'bb-draft-app-2026.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChG9HeDUXGoCLjjZCjOzXvDmcbkpjwirA',
    appId: '1:769860703778:ios:c92960519c3e5642afdc7b',
    messagingSenderId: '769860703778',
    projectId: 'bb-draft-app-2026',
    storageBucket: 'bb-draft-app-2026.firebasestorage.app',
    iosClientId: '769860703778-0buib3d98vpu7a4fijejir73a5fd11ri.apps.googleusercontent.com',
    iosBundleId: 'com.example.bbDraft',
  );

  // TODO: Register a web app in Firebase Console and replace these values

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyALyPlYyz2Hpo4HQnM-l0X6aXuRxIpNzEk',
    appId: '1:769860703778:web:17ecb3dc30116c85afdc7b',
    messagingSenderId: '769860703778',
    projectId: 'bb-draft-app-2026',
    authDomain: 'bb-draft-app-2026.firebaseapp.com',
    storageBucket: 'bb-draft-app-2026.firebasestorage.app',
  );

  // Run: flutterfire configure --platforms=web

  // TODO: Register a macOS app in Firebase Console and replace these values
  // Run: flutterfire configure --platforms=macos
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: '769860703778',
    projectId: 'bb-draft-app-2026',
    storageBucket: 'bb-draft-app-2026.firebasestorage.app',
    iosBundleId: 'com.example.bbDraft',
  );

  // TODO: Register a Windows app in Firebase Console and replace these values
  // Run: flutterfire configure --platforms=windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WINDOWS_API_KEY',
    appId: 'YOUR_WINDOWS_APP_ID',
    messagingSenderId: '769860703778',
    projectId: 'bb-draft-app-2026',
    storageBucket: 'bb-draft-app-2026.firebasestorage.app',
  );

  // TODO: Register a Linux app in Firebase Console and replace these values
  // Run: flutterfire configure --platforms=linux
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR_LINUX_API_KEY',
    appId: 'YOUR_LINUX_APP_ID',
    messagingSenderId: '769860703778',
    projectId: 'bb-draft-app-2026',
    storageBucket: 'bb-draft-app-2026.firebasestorage.app',
  );
}