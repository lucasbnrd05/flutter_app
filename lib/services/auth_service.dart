// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'settings_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // signInAnonymously retiré

  Future<User?> signInWithGoogle() async {
    print("[AuthService] Attempting Google Sign-In...");
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("[AuthService] Google Sign-In cancelled by user.");
        return null;
      }
      print(
          "[AuthService] Google user obtained, getting authentication details...");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print("[AuthService] Creating Firebase credential with Google tokens...");
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print("[AuthService] Signing in to Firebase with Google credential...");
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      print(
          "[AuthService] Firebase Google Sign-In successful: UID ${userCredential.user?.uid}");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print(
          "[AuthService] ERROR Firebase Google Sign-In: ${e.code} - ${e.message}");
      throw e; // Relance pour traitement dans l'UI
    } catch (e) {
      print("[AuthService] UNEXPECTED ERROR during Google Sign-In: $e");
      throw Exception("An unexpected error occurred during Google Sign-In.");
    }
  }

  Future<void> signOut() async {
    final String? userIdBeforeSignOut = _firebaseAuth.currentUser?.uid;
    final bool wasAnonymous = _firebaseAuth.currentUser?.isAnonymous ?? false;
    try {
      final bool isGoogleUser = _firebaseAuth.currentUser?.providerData.any(
              (userInfo) =>
                  userInfo.providerId == GoogleAuthProvider.PROVIDER_ID) ??
          false;
      print(
          "[AuthService] Signing out user ${userIdBeforeSignOut ?? 'unknown'} (was anonymous: $wasAnonymous, was Google: $isGoogleUser)...");
      if (isGoogleUser) {
        print("[AuthService] Signing out from Google as well...");
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
      print("[AuthService] Firebase Sign out successful.");
      print("[AuthService] User settings WERE NOT cleared on sign out.");
    } on FirebaseAuthException catch (e) {
      print("[AuthService] ERROR signing out: ${e.code} - ${e.message}");
    } catch (e) {
      print("[AuthService] UNEXPECTED ERROR signing out: $e");
    }
  }

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      print("[AuthService] Attempting sign-in with email: $email");
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print(
          "[AuthService] Email sign-in successful: UID ${userCredential.user?.uid}");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print(
          "[AuthService] ERROR signing in with email: ${e.code} - ${e.message}");
      throw e;
    } catch (e) {
      print("[AuthService] UNEXPECTED ERROR signing in with email: $e");
      throw Exception("An unexpected error occurred during email sign-in.");
    }
  }

  Future<User?> signUpWithEmailPassword(String email, String password) async {
    try {
      print("[AuthService] Attempting sign-up with email: $email");
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print(
          "[AuthService] Email sign-up successful: UID ${userCredential.user?.uid}");
      // Optionnel: Envoyer un email de vérification
      // await userCredential.user?.sendEmailVerification();
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print(
          "[AuthService] ERROR signing up with email: ${e.code} - ${e.message}");
      throw e;
    } catch (e) {
      print("[AuthService] UNEXPECTED ERROR signing up with email: $e");
      throw Exception("An unexpected error occurred during email sign-up.");
    }
  }
}
