import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:skill_hub/features/chat/domain/services/chat_service.dart';
import 'package:skill_hub/features/chat/presentation/pages/chat_screen.dart';
import 'package:skill_hub/features/home/domain/entities/skill.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Please sign in to view your chats',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to login screen
                  // TODO: Implement navigation to login
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting with skill providers',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }
          
          final chats = snapshot.data!.docs;
          
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              final chatId = chats[index].id;
              final participants = List<String>.from(chat['participants'] ?? []);
              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => '',
              );
              
              if (otherUserId.isEmpty) return const SizedBox.shrink();
              
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  String userName = 'Unknown User';
                  String userPhotoUrl = '';
                  
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData != null) {
                      userName = userData['displayName'] ?? 'Unknown User';
                      userPhotoUrl = userData['photoURL'] ?? '';
                    }
                  }
                  
                  final lastMessage = chat['lastMessage'] as String? ?? '';
                  final lastMessageTime = chat['lastMessageTime'] as Timestamp?;
                  final skillTitle = chat['skillTitle'] as String? ?? 'Skill';
                  final skillId = chat['skillId'] as String? ?? '';
                  
                  String timeString = '';
                  if (lastMessageTime != null) {
                    final dateTime = lastMessageTime.toDate();
                    final now = DateTime.now();
                    
                    if (dateTime.year == now.year && 
                        dateTime.month == now.month && 
                        dateTime.day == now.day) {
                      // Today, show time
                      timeString = DateFormat.jm().format(dateTime);
                    } else if (dateTime.year == now.year && 
                               dateTime.month == now.month && 
                               dateTime.day == now.day - 1) {
                      // Yesterday
                      timeString = 'Yesterday';
                    } else {
                      // Other days, show date
                      timeString = DateFormat.MMMd().format(dateTime);
                    }
                  }
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      backgroundImage: userPhotoUrl.isNotEmpty ? NetworkImage(userPhotoUrl) : null,
                      child: userPhotoUrl.isEmpty
                          ? Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(userName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skillTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: Text(
                      timeString,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    onTap: () async {
                      // Get skill data
                      try {
                        final skillDoc = await _firestore.collection('skills').doc(skillId).get();
                        if (skillDoc.exists) {
                          final skillData = skillDoc.data() as Map<String, dynamic>;
                          
                          // Create a Skill object
                          final skill = Skill(
                            id: skillId,
                            title: skillData['title'] as String? ?? 'Unknown Skill',
                            description: skillData['description'] as String? ?? '',
                            category: skillData['category'] as String? ?? 'General',
                            price: (skillData['price'] as num?)?.toDouble() ?? 0.0,
                            rating: (skillData['rating'] as num?)?.toDouble() ?? 0.0,
                            provider: skillData['provider'] as String? ?? 'Unknown Provider',
                            imageUrl: skillData['imageUrl'] as String? ?? '',
                            createdAt: skillData['createdAt'] != null
                                ? (skillData['createdAt'] as Timestamp).toDate()
                                : DateTime.now(),
                          );
                          
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  providerId: otherUserId,
                                  providerName: userName,
                                  skill: skill,
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error loading chat: $e')),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
