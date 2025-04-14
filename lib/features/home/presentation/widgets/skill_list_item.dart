import 'package:flutter/material.dart';
import 'package:skill_hub/features/home/domain/entities/skill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
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
        if (userData != null && userData['photoURL'] != null) {
          setState(() {
            _providerPhotoUrl = userData['photoURL'];
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

  String _getProviderInitial() {
    if (widget.skill.provider.isEmpty) return '?';
    return widget.skill.provider[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Profile image or initial
              _isLoading
                  ? const CircleAvatar(
                      radius: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      backgroundImage: _providerPhotoUrl != null
                          ? NetworkImage(_providerPhotoUrl!)
                          : null,
                      child: _providerPhotoUrl == null
                          ? Text(
                              _getProviderInitial(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
              const SizedBox(width: 16),
              
              // Skill info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skill title
                    Text(
                      widget.skill.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Provider name
                    Text(
                      widget.skill.provider,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.skill.category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.skill.rating.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
