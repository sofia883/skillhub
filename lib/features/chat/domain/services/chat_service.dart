import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user;
  }

  // Get all chats for the current user
  Stream<QuerySnapshot<Map<String, dynamic>>> getChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: _currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Get messages for a specific chat
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send a message
  Future<void> sendMessage(String chatId, String message) async {
    final batch = _firestore.batch();
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    // Add message to messages subcollection
    batch.set(messageRef, {
      'text': message,
      'senderId': _currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update last message in chat document
    batch.update(chatRef, {
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // Commit the batch
    await batch.commit();
  }

  // Create a new chat or get existing chat
  Future<String> createOrGetChat(
      String otherUserId, String skillId, String skillTitle) async {
    if (otherUserId.isEmpty || skillId.isEmpty) {
      throw ArgumentError('otherUserId and skillId cannot be empty');
    }

    // Create chat ID (sorted to ensure same ID regardless of who initiates)
    final List<String> ids = [_currentUser.uid, otherUserId];
    ids.sort();
    final chatId = '${ids[0]}_${ids[1]}_$skillId';

    // Check if chat exists
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      // Create new chat
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [_currentUser.uid, otherUserId],
        'skillId': skillId,
        'skillTitle': skillTitle,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  // Add method to check if a chat exists
  Future<bool> chatExists(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    return doc.exists;
  }
}
