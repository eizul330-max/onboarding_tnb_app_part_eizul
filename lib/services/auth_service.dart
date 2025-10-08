import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class AuthService {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final SupabaseService _supabaseService = SupabaseService();

  Future<fb.User?> signInWithEmail(String email, String password) async {
    try {
      fb.UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sync user data to Supabase
      await _syncUserToSupabase(userCredential.user!);

      return userCredential.user;
    } on fb.FirebaseAuthException catch (e, s) {
      debugPrint("Error signing in: $e\n$s");
      return null;
    }
  }

  Future<fb.User?> registerWithEmail(String email, String password) async {
    try {
      fb.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on fb.FirebaseAuthException catch (e, s) {
      debugPrint("Error registering: $e\n$s");
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> _syncUserToSupabase(fb.User firebaseUser) async {
    final userData = {
      'uid': firebaseUser.uid,
      'email': firebaseUser.email,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _supabaseService.client.from('users').upsert(userData);
  }
}