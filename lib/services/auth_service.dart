import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔵 Starting Google Sign-In...');
      
      // First, sign out any existing Google account to ensure clean state
      await _googleSignIn.signOut();
      
      // Trigger the authentication flow with timeout
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn()
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              debugPrint('⏱️ Google Sign-In timeout after 60 seconds');
              throw TimeoutException('Google Sign-In timed out. Please try again.');
            },
          );

      if (googleUser == null) {
        // User canceled the sign-in
        debugPrint('❌ Google Sign-In was canceled by user');
        return null;
      }

      debugPrint('✅ Google account selected: ${googleUser.email}');

      // Obtain the auth details from the request
      debugPrint('🔵 Obtaining authentication details...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  debugPrint('⏱️ Authentication details timeout');
                  throw TimeoutException('Failed to get authentication details. Please try again.');
                },
              );

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Missing access token or ID token');
        throw Exception('Failed to obtain authentication tokens from Google');
      }

      debugPrint('✅ Authentication tokens obtained');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      debugPrint('🔵 Signing in to Firebase...');
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential)
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  debugPrint('⏱️ Firebase sign-in timeout');
                  throw TimeoutException('Firebase sign-in timed out. Please try again.');
                },
              );

      // Verify authentication state in Firebase
      final User? firebaseUser = _auth.currentUser;
      
      if (firebaseUser != null) {
        debugPrint('✅ Firebase Authentication SUCCESS');
        debugPrint('   User ID: ${firebaseUser.uid}');
        debugPrint('   Email: ${firebaseUser.email}');
        debugPrint('   Display Name: ${firebaseUser.displayName}');
        debugPrint('   Email Verified: ${firebaseUser.emailVerified}');
        debugPrint('   Provider: ${firebaseUser.providerData.map((p) => p.providerId).join(", ")}');
      } else {
        debugPrint('⚠️ WARNING: UserCredential returned but currentUser is null!');
        throw Exception('Authentication completed but user not found in Firebase');
      }

      debugPrint('✅ Successfully signed in: ${userCredential.user?.email}');
      return userCredential;
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout during Google Sign-In: $e');
      // Sign out from Google to clean up
      await _googleSignIn.signOut();
      rethrow;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      debugPrint('❌ Full error details: ${e.toString()}');
      await _googleSignIn.signOut();
      
      // Provide user-friendly error messages
      String userMessage = 'Sign in failed';
      switch (e.code) {
        case 'network-request-failed':
          userMessage = 'Network error. Please check your internet connection.';
          break;
        case 'invalid-credential':
          userMessage = 'Invalid credentials. Please try again.';
          break;
        case 'account-exists-with-different-credential':
          userMessage = 'An account already exists with this email.';
          break;
        case 'operation-not-allowed':
          userMessage = 'Google Sign-In is not enabled in Firebase. Please enable it in Firebase Console → Authentication → Sign-in method.';
          break;
        case 'invalid-api-key':
          userMessage = 'Firebase configuration error. Please check google-services.json file.';
          break;
        case 'unauthorized-domain':
          userMessage = 'Unauthorized domain. Please check Firebase configuration.';
          break;
        default:
          userMessage = 'Sign in failed: ${e.message ?? e.code}';
      }
      throw Exception(userMessage);
    } catch (e) {
      debugPrint('❌ Error signing in with Google: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      // Sign out from Google to clean up
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
      debugPrint('Successfully signed out');
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get user display name
  String? get displayName => _auth.currentUser?.displayName;

  // Get user email
  String? get email => _auth.currentUser?.email;

  // Get user photo URL
  String? get photoURL => _auth.currentUser?.photoURL;
}

