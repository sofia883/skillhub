import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // Initialize Firebase if needed
    await Firebase.initializeApp();
  }

  Future<User?> createUser({
    required String email,
    required String password,
  }) async {
    try {
      // First create the Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        try {
          // Store user data in Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'email': email,
            'createdAt': Timestamp.now(),
            'uid': user.uid,
            'displayName': email.split('@')[0],
          });
        } catch (e) {
          print('Error storing user data in Firestore: $e');
          // Continue anyway since auth user was created
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown Error: $e');
      rethrow;
    }
  }

  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Login Error: ${e.message}');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Delete user from Firebase Auth
      await user.delete();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if a user exists in Firestore
  Future<bool> checkUserExists(String email) async {
    try {
      // First check Firebase Auth
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        return true;
      }

      // If not found in Auth, check Firestore as fallback
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } on FirebaseAuthException catch (e) {
      // If not found, fetchSignInMethodsForEmail can throw an error
      print('Auth Error checking if user exists: ${e.message}');
      return false;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // Force refresh the current user
  Future<User?> refreshUser() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser;
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile data in Firestore
  Future<void> updateUserData(
      String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(userId).update(userData);
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

  // Update user profile in both Auth and Firestore
  Future<void> updateUserProfile({
    required String displayName,
    String? photoURL,
    String? bio,
    String? phone,
    String? location,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Update Auth profile
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Prepare Firestore data
      final userData = {
        'displayName': displayName,
      };

      if (photoURL != null) userData['photoURL'] = photoURL;
      if (bio != null) userData['bio'] = bio;
      if (phone != null) userData['phone'] = phone;
      if (location != null) userData['location'] = location;

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update(userData);

      // Refresh user
      await refreshUser();
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Delete user account and all associated data
  Future<bool> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final userId = user.uid;

      // 1. Delete user skills from Firestore
      try {
        final skillsSnapshot = await _firestore
            .collection('skills')
            .where('userId', isEqualTo: userId)
            .get();

        // Batch delete all skills
        final batch = _firestore.batch();
        for (var doc in skillsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        print('Error deleting user skills: $e');
        // Continue with deletion process
      }

      // 2. Delete user data from Firestore
      try {
        await _firestore.collection('users').doc(userId).delete();
      } catch (e) {
        print('Error deleting user data: $e');
        // Continue with deletion process
      }

      // 3. Delete the user authentication account
      await user.delete();

      return true;
    } catch (e) {
      print('Error deleting user account: $e');
      rethrow;
    }
  }

  // Upload profile picture to ImgBB and return the URL
  Future<String> uploadProfilePicture(File image) async {
    const String imgbbApiKey = "0c58b6d9015713886842dab7d4825812";

    try {
      // Convert image to base64
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Upload to ImgBB
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': imgbbApiKey,
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data']['display_url'];
        }
        throw Exception('Image upload failed: ${jsonResponse['error']}');
      }

      throw Exception(
          'Image upload failed with status code: ${response.statusCode}');
    } catch (e) {
      print('Error uploading profile picture: $e');
      rethrow;
    }
  }
}
