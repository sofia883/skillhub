import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../domain/entities/skill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../firebase_options.dart';

class SkillRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  // Local cache
  final List<Skill> _localSkills = [];

  // Track when we last refreshed skills
  DateTime? _lastRefreshTime;

  // Constructor that initializes local skills from persistent storage
  SkillRepository() {
    _initializeLocalSkills();
  }

  // Initialize local skills from persistent storage
  Future<void> _initializeLocalSkills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skillsJson = prefs.getString('local_skills');

      if (skillsJson != null && skillsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(skillsJson);
        final skills = decoded.map((item) {
          return Skill(
            id: item['id'],
            title: item['title'],
            description: item['description'],
            category: item['category'],
            price: (item['price'] ?? 0).toDouble(),
            rating: (item['rating'] ?? 0).toDouble(),
            provider: item['provider'],
            imageUrl: item['imageUrl'],
            createdAt: DateTime.parse(item['createdAt']),
            isFeatured: item['isFeatured'] ?? false,
            location: item['location'],
            userId: item['userId'], // Include userId for security rules
          );
        }).toList();

        _localSkills.addAll(skills);
        debugPrint('Loaded ${_localSkills.length} skills from local storage');

        // Start a background refresh to get the latest data
        _refreshSkillsInBackground();
      } else {
        debugPrint('No skills found in local storage, fetching from Firestore');
        // If no local skills, try to fetch from Firestore immediately
        getSkills(forceRefresh: true).then((_) {
          debugPrint('Initial Firestore fetch completed');
        }).catchError((e) {
          debugPrint('Error in initial Firestore fetch: $e');
        });
      }
    } catch (e) {
      debugPrint('Error loading skills from local storage: $e');
    }
  }

  // Save skills to local storage
  Future<void> _saveLocalSkills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skillsJson = jsonEncode(_localSkills
          .map((skill) => {
                'id': skill.id,
                'title': skill.title,
                'description': skill.description,
                'category': skill.category,
                'price': skill.price,
                'rating': skill.rating,
                'provider': skill.provider,
                'imageUrl': skill.imageUrl,
                'createdAt': skill.createdAt.toIso8601String(),
                'isFeatured': skill.isFeatured,
                'location': skill.location,
                'userId': skill.userId, // Include userId for security rules
              })
          .toList());

      await prefs.setString('local_skills', skillsJson);
      debugPrint('Saved ${_localSkills.length} skills to local storage');
    } catch (e) {
      debugPrint('Error saving skills to local storage: $e');
    }
  }

  // Load skills from local storage
  Future<void> _loadLocalSkills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedSkillsJson = prefs.getString('local_skills');

      if (cachedSkillsJson != null && cachedSkillsJson.isNotEmpty) {
        final List<dynamic> decodedSkills = jsonDecode(cachedSkillsJson);

        _localSkills.clear();
        _localSkills.addAll(decodedSkills.map((item) {
          return Skill(
            id: item['id'],
            title: item['title'],
            description: item['description'],
            category: item['category'],
            price: (item['price'] ?? 0).toDouble(),
            rating: (item['rating'] ?? 0).toDouble(),
            provider: item['provider'],
            imageUrl: item['imageUrl'],
            createdAt: DateTime.parse(item['createdAt']),
            isFeatured: item['isFeatured'] ?? false,
            location: item['location'],
            userId: item['userId'],
          );
        }).toList());

        debugPrint('Loaded ${_localSkills.length} skills from local storage');
      } else {
        debugPrint('No cached skills found in local storage');
      }
    } catch (e) {
      debugPrint('Error loading skills from local storage: $e');
    }
  }

  // Check if Firebase is available
  Future<bool> isFirebaseAvailable() async {
    // First check connectivity status
    final connectivityStatus = await _connectivityService.checkConnectivity();
    if (connectivityStatus == ConnectivityStatus.offline) {
      return false;
    }

    try {
      await _firestore
          .collection('test_collection')
          .doc('test_document')
          .set({'timestamp': FieldValue.serverTimestamp()}).timeout(
              const Duration(seconds: 3));

      return true;
    } catch (e) {
      debugPrint('Firebase unavailable: $e');

      return false;
    }
  }

  // Get skills from Firestore or local cache
  Future<List<Skill>> getSkills({bool forceRefresh = false}) async {
    // If we have local skills and we're not forcing a refresh, return them immediately
    // but still refresh in the background
    if (_localSkills.isNotEmpty && !forceRefresh) {
      debugPrint('Using ${_localSkills.length} cached skills');
      // Start a background refresh
      _refreshSkillsInBackground();
      return getAllSkills(); // Return sorted copy
    }

    // If local cache is empty, try to load from local storage first
    if (_localSkills.isEmpty) {
      await _loadLocalSkills();
      if (_localSkills.isNotEmpty) {
        debugPrint('Loaded ${_localSkills.length} skills from local storage');
        // If we got skills from local storage, return them but still fetch from Firestore
        _refreshSkillsInBackground();
        return getAllSkills();
      }
    }

    // Otherwise, try to fetch from Firestore but handle errors gracefully
    try {
      debugPrint('Fetching skills from Firestore...');

      // Create list to hold all skills
      List<Skill> allSkills = [];

      // Try to fetch from Firestore with timeout
      try {
        final skillsSnapshot = await FirebaseFirestore.instance
            .collection('skills')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get()
            .timeout(const Duration(
                seconds: 5)); // Reduced timeout for faster response

        final skills = skillsSnapshot.docs.map((doc) {
          final data = doc.data();
          return _createSkillFromData(data, doc.id);
        }).toList();

        allSkills.addAll(skills);
        debugPrint('Loaded ${skills.length} skills from Firestore');
      } catch (e) {
        debugPrint('Error fetching from Firestore: $e');
        // Show more detailed error information
        if (e is FirebaseException) {
          debugPrint('Firebase error code: ${e.code}');
          debugPrint('Firebase error message: ${e.message}');
        }
        // Continue with local skills
      }

      // If we got skills from Firestore, update local cache
      if (allSkills.isNotEmpty) {
        _localSkills.clear();
        _localSkills.addAll(allSkills);
        // Save to local storage for future use
        await _saveLocalSkills();
        debugPrint(
            'Updated local cache with ${allSkills.length} skills from Firestore');
        return getAllSkills(); // Return sorted copy
      } else {
        // If we didn't get any skills from Firestore, return whatever we have in local cache
        debugPrint(
            'No skills from Firestore, returning ${_localSkills.length} local skills');
        return getAllSkills();
      }
    } catch (e) {
      debugPrint('Error in getSkills: $e');
      // Return whatever we have in local cache
      return getAllSkills();
    }
  }

  // Refresh skills in the background without blocking the UI
  Future<void> _refreshSkillsInBackground() async {
    debugPrint('Starting background refresh of skills...');
    try {
      final skillsSnapshot = await FirebaseFirestore.instance
          .collection('skills')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get()
          .timeout(const Duration(seconds: 10));

      final skills = skillsSnapshot.docs.map((doc) {
        final data = doc.data();
        return _createSkillFromData(data, doc.id);
      }).toList();

      if (skills.isNotEmpty) {
        // Compare with existing skills to see if there are any changes
        final existingIds = _localSkills.map((s) => s.id).toSet();
        final newIds = skills.map((s) => s.id).toSet();

        // Check if there are any new skills
        final hasNewSkills = newIds.difference(existingIds).isNotEmpty;
        // Check if any existing skills are missing from the new data
        final hasMissingSkills = existingIds.difference(newIds).isNotEmpty;

        if (hasNewSkills || hasMissingSkills) {
          debugPrint('Changes detected in background refresh:');
          if (hasNewSkills) {
            debugPrint(
                '- New skills: ${newIds.difference(existingIds).length}');
          }
          if (hasMissingSkills) {
            debugPrint(
                '- Removed skills: ${existingIds.difference(newIds).length}');
          }

          // Update local cache
          _localSkills.clear();
          _localSkills.addAll(skills);
          await _saveLocalSkills();
          _lastRefreshTime = DateTime.now();
          debugPrint(
              'Background refresh completed: ${skills.length} skills updated at $_lastRefreshTime');
        } else {
          debugPrint('No changes detected in background refresh');
        }
      }
    } catch (e) {
      debugPrint('Background refresh failed: $e');
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
      debugPrint('Error fetching user skills: $e');
      return [];
    }
  }

  // Get all skills from local cache immediately (no async)
  List<Skill> getAllSkills() {
    // If local cache is empty, try to load from local storage synchronously
    if (_localSkills.isEmpty) {
      debugPrint('Local cache is empty, trying to load from local storage');
      // We can't use await here since this method is not async,
      // but we can trigger the load for next time
      _loadLocalSkills();
    }

    // Make a copy of the local skills
    final List<Skill> skills = List<Skill>.from(_localSkills);

    // Remove duplicates by ID
    final Map<String, Skill> uniqueSkills = {};
    for (final skill in skills) {
      uniqueSkills[skill.id] = skill;
    }
    final uniqueSkillsList = uniqueSkills.values.toList();

    // Sort by creation date (newest first)
    if (uniqueSkillsList.isNotEmpty) {
      uniqueSkillsList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    debugPrint(
        'getAllSkills: Returning ${uniqueSkillsList.length} skills from local cache');
    return uniqueSkillsList;
  }

  // Search skills - always use local cache for better performance
  Future<List<Skill>> searchSkills(String query, String category) async {
    try {
      // Always use local cache for searching to avoid UI lag
      List<Skill> skillsList = List.from(_localSkills);

      // Apply category filter
      if (category != 'All') {
        skillsList =
            skillsList.where((skill) => skill.category == category).toList();
      }

      debugPrint(
          'Searching ${skillsList.length} skills in "$category" category for "$query"');

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
      debugPrint('Error searching skills: $e');
      return [];
    }
  }

  // Add a new skill
  Future<bool> addSkill(Map<String, dynamic> skillData) async {
    try {
      // Create a unique ID for the skill if not already present
      if (!skillData.containsKey('id') || skillData['id'] == null) {
        final skillId = DateTime.now().millisecondsSinceEpoch.toString();
        skillData['id'] = skillId;
      }
      final skillId = skillData['id'] as String;

      // Ensure all required fields are present
      if (!skillData.containsKey('createdAt')) {
        skillData['createdAt'] = FieldValue.serverTimestamp();
      }

      debugPrint('✅ Adding skill: ${skillData['title']} with ID: $skillId');

      // Create a skill entity for local cache
      final newSkill = Skill(
        id: skillId,
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
        location: skillData['location'],
      );

      // Always add to local cache first for immediate UI update
      _localSkills.insert(0, newSkill);
      debugPrint('Added skill to local cache: ${newSkill.title}');

      // Save to local storage
      await _saveLocalSkills();

      // Try to save to Firebase immediately but don't block UI
      bool firebaseSuccess = false;
      try {
        // First attempt to save to Firebase
        firebaseSuccess = await _tryFirebaseSave(skillData);

        if (firebaseSuccess) {
          debugPrint('✅ Skill saved to Firebase successfully on first try');
        } else {
          // If first attempt fails, try again immediately
          debugPrint(
              '⚠️ First attempt to save to Firebase failed, trying again...');
          firebaseSuccess = await _tryFirebaseSave(skillData);

          if (firebaseSuccess) {
            debugPrint('✅ Skill saved to Firebase successfully on second try');
          } else {
            debugPrint('❌ Failed to save skill to Firebase after two attempts');
            // Schedule a retry for later
            _scheduleFirebaseRetry(skillData);
          }
        }
      } catch (firebaseError) {
        debugPrint('❌ Error saving to Firebase: $firebaseError');
        // Schedule a retry for later
        _scheduleFirebaseRetry(skillData);
      }

      // Return true if we saved to Firebase or at least locally
      return true;
    } catch (e) {
      debugPrint('❌ Error adding skill: $e');
      return false;
    }
  }

  // Try to save to Firebase but don't block the UI
  Future<bool> _tryFirebaseSave(Map<String, dynamic> skillData) async {
    try {
      // Get the skill ID from the data
      final String skillId = skillData['id'] as String;

      // Check if Firebase is initialized
      if (!Firebase.apps.isNotEmpty) {
        debugPrint('Firebase not initialized, trying to initialize now...');
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          debugPrint('Firebase initialized successfully in _tryFirebaseSave');
        } catch (initError) {
          debugPrint('Failed to initialize Firebase: $initError');
          return false;
        }
      }

      // Convert DateTime to Timestamp for Firestore
      Map<String, dynamic> firestoreData = Map.from(skillData);
      if (firestoreData['createdAt'] is DateTime) {
        firestoreData['createdAt'] =
            Timestamp.fromDate(firestoreData['createdAt'] as DateTime);
      }

      // Make sure we have a user ID for Firestore security rules
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Add the user ID to the data for security rules
        firestoreData['userId'] = currentUser.uid;
        debugPrint('✅ Adding user ID to skill data: ${currentUser.uid}');
      } else {
        // Try to sign in anonymously if we don't have a user
        try {
          final userCredential =
              await FirebaseAuth.instance.signInAnonymously();
          firestoreData['userId'] = userCredential.user!.uid;
          debugPrint(
              '✅ Signed in anonymously and added user ID: ${userCredential.user!.uid}');
        } catch (e) {
          debugPrint('⚠️ Could not sign in anonymously: $e');
          // Continue anyway, but this might fail due to security rules
        }
      }

      // Log the data being saved
      debugPrint(
          'Saving skill to Firestore: ${firestoreData['title']} with ID: $skillId');

      // Use set with merge option to ensure we don't overwrite existing data
      await FirebaseFirestore.instance
          .collection('skills')
          .doc(skillId)
          .set(firestoreData, SetOptions(merge: true))
          .timeout(const Duration(seconds: 15));

      debugPrint('✅ Successfully saved skill to Firestore with ID: $skillId');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving to Firebase: $e');
      // Show more detailed error information
      if (e is FirebaseException) {
        debugPrint('Firebase error code: ${e.code}');
        debugPrint('Firebase error message: ${e.message}');
      } else if (e is TimeoutException) {
        debugPrint(
            'Firebase operation timed out. Check your internet connection.');
      }
      return false;
    }
  }

  // Schedule a retry for Firebase save
  void _scheduleFirebaseRetry(Map<String, dynamic> skillData) {
    // Wait for 30 seconds before retrying
    Future.delayed(const Duration(seconds: 30), () async {
      debugPrint('Retrying to save skill to Firebase: ${skillData['title']}');
      final success = await _tryFirebaseSave(skillData);
      if (!success) {
        // If still failed, schedule another retry with exponential backoff
        Future.delayed(const Duration(minutes: 2), () {
          _tryFirebaseSave(skillData);
        });
      }
    });
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
      debugPrint('Error deleting skill: $e');
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
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now())
          : DateTime.now(),
      isFeatured: data['isFeatured'] ?? false,
      location: data['location'],
      userId: data['userId'], // Include userId for security rules
    );
  }
}
