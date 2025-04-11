import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all chats for the current user
  Stream<QuerySnapshot> getChats() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Get messages for a specific chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send a message
  Future<void> sendMessage(String chatId, String message) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Add message to messages subcollection
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'text': message,
      'senderId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update last message in chat document
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Create a new chat or get existing chat
  Future<String> createOrGetChat(String otherUserId, String skillId, String skillTitle) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Create chat ID (sorted to ensure same ID regardless of who initiates)
    final List<String> ids = [user.uid, otherUserId];
    ids.sort();
    final chatId = '${ids[0]}_${ids[1]}_$skillId';

    // Check if chat exists
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    
    if (!chatDoc.exists) {
      // Create new chat
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [user.uid, otherUserId],
        'skillId': skillId,
        'skillTitle': skillTitle,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }
}
