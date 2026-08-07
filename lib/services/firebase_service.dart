import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../firebase_options.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      // Load environment configuration from ~/RepCount/.env
      await dotenv.load(fileName: '/home/mohittokas/RepCount/.env');
      debugPrint('🔑 Loaded Firebase configuration from ~/RepCount/.env');
    } catch (e) {
      debugPrint('⚠️ Could not load ~/RepCount/.env file, falling back to embedded defaults.');
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Enforce Firestore Offline Persistence & Caching settings
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      debugPrint('🔥 Firebase initialized for project: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    } catch (e) {
      debugPrint('⚠️ Firebase Initialization status: $e');
    }
  }
}
