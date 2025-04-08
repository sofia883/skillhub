import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
}
