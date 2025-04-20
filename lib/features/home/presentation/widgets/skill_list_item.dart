import 'package:flutter/material.dart';
import 'package:skill_hub/features/home/domain/entities/skill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_hub/features/chat/presentation/pages/chat_screen.dart';
import 'package:skill_hub/features/home/presentation/widgets/provider_card.dart';
import 'package:shimmer/shimmer.dart';

class SkillListItem extends StatefulWidget {
  final Skill skill;
  final VoidCallback? onTap;

  const SkillListItem({
    Key? key,
    required this.skill,
    this.onTap,
  }) : super(key: key);

  @override
  State<SkillListItem> createState() => _SkillListItemState();
}

class _SkillListItemState extends State<SkillListItem> {
  String? _providerPhotoUrl;
  bool _isLoading = true;
  bool _isOnline = false;
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    // If we already have the provider data in the skill model, use that
    if (widget.skill.providerImageUrl != null) {
      setState(() {
        _providerPhotoUrl = widget.skill.providerImageUrl;
        _isOnline = widget.skill.isOnline ?? false;
        _lastSeen = widget.skill.lastSeen;
        _isLoading = false;
      });
      return;
    }

    if (widget.skill.userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.skill.userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          setState(() {
            _providerPhotoUrl = userData['photoURL'];
            _isOnline = userData['isOnline'] ?? false;
            if (userData['lastSeen'] != null) {
              _lastSeen = (userData['lastSeen'] as Timestamp).toDate();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading provider data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleChat() {
    if (widget.skill.userId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          providerId: widget.skill.userId!,
          providerName: widget.skill.provider,
          skill: widget.skill,
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 200,
                    height: 20,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 16,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Container(
                width: 200,
                height: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    return ProviderCard(
      providerId: widget.skill.userId ?? '',
      providerName: widget.skill.provider,
      profileImage: _providerPhotoUrl,
      location: widget.skill.location,
      description: widget.skill.description,
      skills: [widget.skill.category],
      experienceImages: widget.skill.experienceImages,
      rating: widget.skill.rating.toInt(),
      reviewCount: widget.skill.reviewCount ?? 0,
      isOnline: _isOnline,
      lastSeen: _lastSeen,
      isVerified: widget.skill.isVerified,
      onChat: _handleChat,
      onViewProfile: widget.onTap ?? () {},
      hourlyRate: widget.skill.hourlyRate,
      education: widget.skill.education,
      experience: widget.skill.experience,
      certifications: widget.skill.certifications,
      languages: widget.skill.languages,
      availability: widget.skill.availability,
    );
  }
}
