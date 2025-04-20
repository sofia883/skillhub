import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/provider_model.dart';

class ProviderRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Get all providers except current user
  Stream<List<ProviderModel>> getProvidersStream({
    String? category,
    String? searchQuery,
    String? location,
    bool excludeCurrentUser = true,
  }) {
    Query query = _firestore.collection('providers');

    // Apply filters
    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('skills', arrayContains: category);
    }

    if (location != null && location.isNotEmpty) {
      query = query.where('location', isEqualTo: location);
    }

    // Exclude current user if logged in
    final currentUser = _auth.currentUser;
    if (excludeCurrentUser && currentUser != null) {
      query = query.where('id', isNotEqualTo: currentUser.uid);
    }

    // Order by rating and online status
    query = query
        .orderBy('isOnline', descending: true)
        .orderBy('rating', descending: true);

    return query.snapshots().map((snapshot) {
      final providers =
          snapshot.docs.map((doc) => ProviderModel.fromFirestore(doc)).toList();

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        return providers.where((provider) {
          final searchLower = searchQuery.toLowerCase();
          return provider.name.toLowerCase().contains(searchLower) ||
              provider.description.toLowerCase().contains(searchLower) ||
              provider.skills
                  .any((skill) => skill.toLowerCase().contains(searchLower)) ||
              (provider.location?.toLowerCase().contains(searchLower) ?? false);
        }).toList();
      }

      return providers;
    });
  }

  // Get single provider by ID
  Future<ProviderModel?> getProviderById(String providerId) async {
    try {
      final doc =
          await _firestore.collection('providers').doc(providerId).get();
      if (doc.exists) {
        return ProviderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting provider: $e');
      return null;
    }
  }

  // Update provider online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('providers').doc(currentUser.uid).update({
          'isOnline': isOnline,
          'lastSeen': isOnline ? null : FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  // Get recommended providers based on user's interests
  Future<List<ProviderModel>> getRecommendedProviders({int limit = 5}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Get user's interests
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final interests = List<String>.from(userDoc.data()?['interests'] ?? []);

      if (interests.isEmpty) {
        // If no interests, return top-rated providers
        final snapshot = await _firestore
            .collection('providers')
            .where('id', isNotEqualTo: currentUser.uid)
            .orderBy('id')
            .orderBy('rating', descending: true)
            .limit(limit)
            .get();

        return snapshot.docs
            .map((doc) => ProviderModel.fromFirestore(doc))
            .toList();
      }

      // Get providers matching user's interests
      final snapshot = await _firestore
          .collection('providers')
          .where('skills', arrayContainsAny: interests)
          .where('id', isNotEqualTo: currentUser.uid)
          .orderBy('id')
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProviderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting recommended providers: $e');
      return [];
    }
  }

  // Get nearby providers
  Future<List<ProviderModel>> getNearbyProviders({
    required String location,
    double radius = 10, // in kilometers
    int limit = 10,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // For now, simple location matching
      // TODO: Implement proper geolocation querying
      final snapshot = await _firestore
          .collection('providers')
          .where('location', isEqualTo: location)
          .where('id', isNotEqualTo: currentUser.uid)
          .orderBy('id')
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProviderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting nearby providers: $e');
      return [];
    }
  }
}
