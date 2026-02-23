import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class UserProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _customPhotoUrlKey = 'user_custom_photo_url';

  // Get current user's profile photo URL
  // Priority: Custom uploaded photo > Firebase Auth photo > null
  Future<String?> getProfilePhotoUrl() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Check for custom uploaded photo first
    final prefs = await SharedPreferences.getInstance();
    final customPhotoUrl = prefs.getString(_customPhotoUrlKey);
    if (customPhotoUrl != null && customPhotoUrl.isNotEmpty) {
      return customPhotoUrl;
    }

    // Fall back to Firebase Auth photo
    return user.photoURL;
  }

  // Upload custom profile picture
  Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload to Firebase Storage
      final ref = _storage.ref().child('profile_pictures/${user.uid}.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      // Save to local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customPhotoUrlKey, downloadUrl);

      debugPrint('Profile picture uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      rethrow;
    }
  }

  // Remove custom profile picture (revert to Firebase Auth photo)
  Future<void> removeCustomProfilePicture() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Delete from Firebase Storage
      final ref = _storage.ref().child('profile_pictures/${user.uid}.jpg');
      await ref.delete().catchError((e) {
        debugPrint('Error deleting from storage (may not exist): $e');
      });

      // Remove from local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customPhotoUrlKey);

      debugPrint('Custom profile picture removed');
    } catch (e) {
      debugPrint('Error removing custom profile picture: $e');
      rethrow;
    }
  }

  // Get user display name
  String? getDisplayName() {
    return _auth.currentUser?.displayName;
  }

  // Get user email
  String? getEmail() {
    return _auth.currentUser?.email;
  }
}







