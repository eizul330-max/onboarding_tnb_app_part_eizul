import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final SupabaseService _supabaseService = SupabaseService();

  Future<fb.User?> signInWithEmail(String email, String password) async {
    try {
      // 1. Sign in to Firebase first
      final fb.UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. If Firebase login is successful, also sign in to Supabase
      if (userCredential.user != null) {
        await _supabaseService.client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        // Sync user data after both logins are successful
        await _syncUserToSupabase(userCredential.user!);
      }

      return userCredential.user;
    } on fb.FirebaseAuthException catch (e) {
      print("Firebase sign-in error: ${e.message}");
      return null;
    } on AuthException catch (e) {
      print("Supabase sign-in error: ${e.message}");
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
    } catch (e) {
      print("Error registering: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _supabaseService.client.auth.signOut();
  }

  Future<void> _syncUserToSupabase(fb.User firebaseUser) async {
    final userData = {
      'uid': firebaseUser.uid,
      'email': firebaseUser.email,
      'createdat': DateTime.now().toIso8601String(),
    };

    await _supabaseService.client.from('users').upsert(userData);
  }
}