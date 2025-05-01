// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'settings_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? getCurrentUser() { return _firebaseAuth.currentUser; }
  Future<User?> signInAnonymously() async { /* ... inchangé ... */ try { print("[AuthService] Attempting anonymous sign-in..."); final userCredential = await _firebaseAuth.signInAnonymously(); print("[AuthService] Anonymous sign-in successful: UID ${userCredential.user?.uid}"); return userCredential.user; } on FirebaseAuthException catch (e) { print("[AuthService] ERROR signing in anonymously: ${e.code} - ${e.message}"); return null; } catch (e) { print("[AuthService] UNEXPECTED ERROR signing in anonymously: $e"); return null; } }
  Future<User?> signInWithGoogle() async { /* ... inchangé ... */ print("[AuthService] Attempting Google Sign-In..."); try { final GoogleSignInAccount? googleUser = await _googleSignIn.signIn(); if (googleUser == null) { print("[AuthService] Google Sign-In cancelled by user."); return null; } print("[AuthService] Google user obtained, getting authentication details..."); final GoogleSignInAuthentication googleAuth = await googleUser.authentication; print("[AuthService] Creating Firebase credential with Google tokens..."); final OAuthCredential credential = GoogleAuthProvider.credential( accessToken: googleAuth.accessToken, idToken: googleAuth.idToken, ); print("[AuthService] Signing in to Firebase with Google credential..."); final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential); print("[AuthService] Firebase Google Sign-In successful: UID ${userCredential.user?.uid}"); return userCredential.user; } on FirebaseAuthException catch (e) { print("[AuthService] ERROR Firebase Google Sign-In: ${e.code} - ${e.message}"); return null; } catch (e) { print("[AuthService] UNEXPECTED ERROR during Google Sign-In: $e"); return null; } }
  Future<void> signOut() async { /* ... inchangé (sans clearUserSettings) ... */ final String? userIdBeforeSignOut = _firebaseAuth.currentUser?.uid; final bool wasAnonymous = _firebaseAuth.currentUser?.isAnonymous ?? false; try { final bool isGoogleUser = _firebaseAuth.currentUser?.providerData .any((userInfo) => userInfo.providerId == GoogleAuthProvider.PROVIDER_ID) ?? false; print("[AuthService] Signing out user ${userIdBeforeSignOut ?? 'unknown'} (was anonymous: $wasAnonymous, was Google: $isGoogleUser)..."); if (isGoogleUser) { print("[AuthService] Signing out from Google as well..."); await _googleSignIn.signOut(); } await _firebaseAuth.signOut(); print("[AuthService] Firebase Sign out successful."); print("[AuthService] User settings WERE NOT cleared on sign out."); } on FirebaseAuthException catch (e) { print("[AuthService] ERROR signing out: ${e.code} - ${e.message}"); } catch (e) { print("[AuthService] UNEXPECTED ERROR signing out: $e"); } }

  // --- Connexion Email/Password (IMPLÉMENTÉE) ---
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      print("[AuthService] Attempting sign-in with email: $email"); // Log l'email
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(), // Toujours .trim() l'email
        password: password, // Ne pas trim le mot de passe
      );
      print("[AuthService] Email sign-in successful: UID ${userCredential.user?.uid}");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Loggue les erreurs spécifiques communes
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        print("[AuthService] ERROR signing in with email: Invalid credentials (user not found or wrong password). Code: ${e.code}");
      } else if (e.code == 'invalid-email') {
        print("[AuthService] ERROR signing in with email: Invalid email format. Code: ${e.code}");
      } else {
        print("[AuthService] ERROR signing in with email: ${e.code} - ${e.message}");
      }
      // Retourne null pour indiquer l'échec à l'UI
      return null;
    } catch (e) {
      print("[AuthService] UNEXPECTED ERROR signing in with email: $e");
      return null;
    }
  }

  // --- Inscription Email/Password (IMPLÉMENTÉE) ---
  Future<User?> signUpWithEmailPassword(String email, String password) async {
    try {
      print("[AuthService] Attempting sign-up with email: $email");
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password, // Firebase gère le hachage et les règles de complexité (si activées)
      );
      print("[AuthService] Email sign-up successful: UID ${userCredential.user?.uid}");
      // Optionnel: Envoyer un email de vérification si tu l'as activé dans les modèles Firebase Auth
      // try {
      //    await userCredential.user?.sendEmailVerification();
      //    print("[AuthService] Verification email sent (if user exists).");
      // } catch (e) {
      //    print("[AuthService] Failed to send verification email: $e");
      // }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Loggue les erreurs spécifiques communes
      if (e.code == 'weak-password') {
        print('[AuthService] ERROR signing up with email: The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('[AuthService] ERROR signing up with email: The account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        print("[AuthService] ERROR signing up with email: Invalid email format. Code: ${e.code}");
      } else {
        print("[AuthService] ERROR signing up with email: ${e.code} - ${e.message}");
      }
      // Retourne null pour indiquer l'échec à l'UI
      return null;
    } catch (e) {
      print("[AuthService] UNEXPECTED ERROR signing up with email: $e");
      return null;
    }
  }
}