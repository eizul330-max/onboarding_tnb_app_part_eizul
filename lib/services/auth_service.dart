import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final SupabaseService _supabaseService = SupabaseService();

  Future<fb.User?> signInWithEmail(String email, String password) async {
  try {
    fb.UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Sync user data to Supabase only if user successfully logs in
    if (userCredential.user != null) {
      try {
        // Get the Firebase ID token
        final firebaseToken = await userCredential.user?.getIdToken();
        if (firebaseToken != null) {
          // Sign in to Supabase with the Firebase token
          await _supabaseService.signInWithFirebaseToken(firebaseToken);
          // Now that Supabase is authenticated, sync the user data.
          await _syncUserToSupabase(userCredential.user!);
        }
      } catch (e) {
        print("Error during post-login sync: $e");
        // Do not return null just because sync failed, user can still log in
      }
    }

    return userCredential.user;
  } catch (e) {
    print("Error signing in: $e");
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