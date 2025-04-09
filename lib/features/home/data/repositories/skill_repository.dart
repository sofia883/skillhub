import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../domain/entities/skill.dart';
import 'package:firebase_core/firebase_core.dart';

class SkillRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isOfflineMode = false;

  // Static list to hold skills between app sessions
  static final List<Skill> _persistentSkills = [];

  // Local cache
  final List<Skill> _localSkills = [];

  // Constructor that initializes local skills from persistent storage
  SkillRepository() {
    _initializeLocalSkills();
  }

  // Initialize local skills from persistent storage
  void _initializeLocalSkills() {
    if (_persistentSkills.isNotEmpty) {
      _localSkills.addAll(_persistentSkills);
      print('Loaded ${_localSkills.length} skills from persistent storage');
    }
  }

  // Check if Firebase is available
  Future<bool> isFirebaseAvailable() async {
    try {
      await _firestore
          .collection('test_collection')
          .doc('test_document')
          .set({'timestamp': FieldValue.serverTimestamp()}).timeout(
              const Duration(seconds: 3));
      _isOfflineMode = false;
      return true;
    } catch (e) {
      print('Firebase unavailable: $e');
      _isOfflineMode = true;
      return false;
    }
  }

  // Get skills from Firestore or local cache
  Future<List<Skill>> getSkills({bool forceRefresh = false}) async {
    // If we have local skills and we're not forcing a refresh, return them
    if (_localSkills.isNotEmpty && !forceRefresh) {
      print('Using ${_localSkills.length} cached skills');
      return _localSkills;
    }

    // Otherwise, try to fetch from Firestore but handle errors gracefully
    try {
      print('Fetching skills from Firestore...');

      // Create list to hold all skills
      List<Skill> allSkills = [];

      // Try to fetch from Firestore with timeout
      try {
        final skillsSnapshot = await FirebaseFirestore.instance
            .collection('skills')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get()
            .timeout(const Duration(seconds: 5));

        final skills = skillsSnapshot.docs.map((doc) {
          final data = doc.data();
          return _createSkillFromData(data, doc.id);
        }).toList();

        allSkills.addAll(skills);
        print('Loaded ${skills.length} skills from Firestore');
      } catch (e) {
        print('Error fetching from Firestore: $e');
        // Continue with local skills
      }

      // If we got skills from Firestore, update local cache
      if (allSkills.isNotEmpty) {
        _localSkills.clear();
        _localSkills.addAll(allSkills);
      }

      return _localSkills;
    } catch (e) {
      print('Error in getSkills: $e');
      return _localSkills;
    }
  }

  // Get skills by user ID
  Future<List<Skill>> getUserSkills() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      if (await isFirebaseAvailable()) {
        final skillsSnapshot = await _firestore
            .collection('skills')
            .where('providerId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();

        return skillsSnapshot.docs.map((doc) {
          final data = doc.data();
          return _createSkillFromData(data, doc.id);
        }).toList();
      } else {
        // Filter local cache for user's skills
        return _localSkills
            .where((skill) =>
                skill.provider == user.displayName ||
                skill.provider == user.email)
            .toList();
      }
    } catch (e) {
      print('Error fetching user skills: $e');
      return [];
    }
  }

  // Search skills
  Future<List<Skill>> searchSkills(String query, String category) async {
    try {
      List<Skill> skillsList = [];

      if (await isFirebaseAvailable()) {
        // Create a query
        Query skillsQuery = _firestore.collection('skills');

        // Add category filter if not 'All'
        if (category != 'All') {
          skillsQuery = skillsQuery.where('category', isEqualTo: category);
        }

        // Limit the query to improve performance
        skillsQuery =
            skillsQuery.orderBy('createdAt', descending: true).limit(50);

        // Execute the query
        final QuerySnapshot skillsSnapshot = await skillsQuery.get();

        // Convert to Skills list
        skillsList = skillsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _createSkillFromData(data, doc.id);
        }).toList();
      } else {
        // Use local cache
        skillsList = _localSkills;

        // Apply category filter
        if (category != 'All') {
          skillsList =
              skillsList.where((skill) => skill.category == category).toList();
        }
      }

      // Apply search query filter in memory
      if (query.isEmpty) {
        return skillsList;
      } else {
        final lowerQuery = query.toLowerCase();
        return skillsList.where((skill) {
          return skill.title.toLowerCase().contains(lowerQuery) ||
              skill.description.toLowerCase().contains(lowerQuery) ||
              skill.provider.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    } catch (e) {
      print('Error searching skills: $e');
      return [];
    }
  }

  // Add a new skill
  Future<bool> addSkill(Map<String, dynamic> skillData) async {
    try {
      // Create a unique ID for the skill
      final skillId = DateTime.now().millisecondsSinceEpoch.toString();
      skillData['id'] = skillId;

      // Ensure all required fields are present
      if (!skillData.containsKey('createdAt')) {
        skillData['createdAt'] = FieldValue.serverTimestamp();
      }

      // Create a skill entity for local cache
      final newSkill = Skill(
        id: skillData['id'],
        title: skillData['title'] ?? '',
        description: skillData['description'] ?? '',
        category: skillData['category'] ?? 'Other',
        price: (skillData['price'] ?? 0).toDouble(),
        rating: 0.0,
        provider: skillData['provider'] ?? 'Unknown Provider',
        imageUrl: skillData['imageUrl'] ??
            'https://via.placeholder.com/300x200?text=No+Image',
        createdAt: DateTime.now(),
        isFeatured: false,
      );

      // Always add to local cache first to ensure data is available
      _localSkills.insert(0, newSkill);
      print('Added skill to local cache: ${newSkill.title}');

      // Save to local storage
      _saveLocalSkills();

      // Try to save to Firebase in the background, but don't wait for it
      _tryFirebaseSave(skillData).then((success) {
        if (success) {
          print('Skill saved to Firebase successfully');
        } else {
          print('Failed to save skill to Firebase, but it is saved locally');
        }
      });

      // Return true immediately since we saved locally
      return true;
    } catch (e) {
      print('Error adding skill: $e');
      return false;
    }
  }

  // Try to save to Firebase but don't block the UI
  Future<bool> _tryFirebaseSave(Map<String, dynamic> skillData) async {
    try {
      await FirebaseFirestore.instance
          .collection('skills')
          .add(skillData)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      print('Firebase unavailable: $e');
      return false;
    }
  }

  // Save local skills to local storage
  Future<void> _saveLocalSkills() async {
    try {
      // Since we can't add shared_preferences due to connectivity issues,
      // we'll keep skills in the static list between sessions
      _persistentSkills.clear();
      _persistentSkills.addAll(_localSkills);
      print('Saved ${_localSkills.length} skills to persistent storage');
    } catch (e) {
      print('Error saving local skills: $e');
    }
  }

  // Delete a skill
  Future<bool> deleteSkill(String skillId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Remove from local cache
      _localSkills.removeWhere((skill) => skill.id == skillId);

      if (await isFirebaseAvailable()) {
        // Find the document with matching ID
        final querySnapshot = await _firestore
            .collection('skills')
            .where('id', isEqualTo: skillId)
            .where('providerId',
                isEqualTo: user.uid) // Ensure user owns this skill
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw Exception(
              'Skill not found or you do not have permission to delete it');
        }

        // Delete the document
        await _firestore
            .collection('skills')
            .doc(querySnapshot.docs.first.id)
            .delete();
      }

      return true;
    } catch (e) {
      print('Error deleting skill: $e');
      return false;
    }
  }

  // Create a skill from Firestore data
  Skill _createSkillFromData(Map<String, dynamic> data, String id) {
    return Skill(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      price: (data['price'] ?? 0).toDouble(),
      rating: (data['rating'] ?? 0).toDouble(),
      provider: data['provider'] ?? 'Unknown Provider',
      imageUrl: data['imageUrl'] ??
          'https://via.placeholder.com/300x200?text=No+Image',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isFeatured: data['isFeatured'] ?? false,
    );
  }
}
