import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      debugPrint('🔑 Signed in anonymously with UID: ${credential.user?.uid}');
      return credential.user;
    } catch (e) {
      debugPrint('⚠️ Anonymous sign in warning (offline mode): $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
