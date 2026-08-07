import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
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
      default:
        return web;
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: dotenv.env['EXPO_PUBLIC_FIREBASE_API_KEY'] ??
            'AIzaSyBZVcuiD7lGHqWx6NpF8IiMTZRGw2nVRkg',
        appId: dotenv.env['EXPO_PUBLIC_FIREBASE_APP_ID'] ??
            '1:596487429514:web:5f6cc0df7f98eb0d20bc73',
        messagingSenderId: dotenv.env['EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID'] ??
            '596487429514',
        projectId: dotenv.env['EXPO_PUBLIC_FIREBASE_PROJECT_ID'] ??
            'repcount-app-2026',
        authDomain: dotenv.env['EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN'] ??
            'repcount-app-2026.firebaseapp.com',
        storageBucket: dotenv.env['EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET'] ??
            'repcount-app-2026.firebasestorage.app',
      );

  static FirebaseOptions get android => web;
  static FirebaseOptions get ios => web;
}
