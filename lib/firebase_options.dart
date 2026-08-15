import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static String _getEnv(String key, String fallback) {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env[key] ?? fallback;
      }
    } catch (_) {}
    return fallback;
  }

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
        apiKey: _getEnv('EXPO_PUBLIC_FIREBASE_API_KEY',
            'AIzaSyBZVcuiD7lGHqWx6NpF8IiMTZRGw2nVRkg'),
        appId: _getEnv('EXPO_PUBLIC_FIREBASE_APP_ID',
            '1:596487429514:web:5f6cc0df7f98eb0d20bc73'),
        messagingSenderId: _getEnv('EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID',
            '596487429514'),
        projectId: _getEnv('EXPO_PUBLIC_FIREBASE_PROJECT_ID',
            'repcount-app-2026'),
        authDomain: _getEnv('EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN',
            'repcount-app-2026.firebaseapp.com'),
        storageBucket: _getEnv('EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET',
            'repcount-app-2026.firebasestorage.app'),
      );

  static FirebaseOptions get android => web;
  static FirebaseOptions get ios => web;
}
