import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProviderCard extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String? profileImage;
  final String? location;
  final String description;
  final List<String> skills;
  final List<String>? experienceImages;
  final int rating;
  final int reviewCount;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isVerified;
  final VoidCallback onChat;
  final VoidCallback onViewProfile;
  final double? hourlyRate;
  final String? education;
  final String? experience;
  final List<String>? certifications;
  final List<String>? languages;
  final String? availability;

  const ProviderCard({
    super.key,
    required this.providerId,
    required this.providerName,
    this.profileImage,
    this.location,
    required this.description,
    required this.skills,
    this.experienceImages,
    required this.rating,
    required this.reviewCount,
    this.isOnline = false,
    this.lastSeen,
    this.isVerified = false,
    required this.onChat,
    required this.onViewProfile,
    this.hourlyRate,
    this.education,
    this.experience,
    this.certifications,
    this.languages,
    this.availability,
  });

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildInitials(ThemeData theme) {
    final initials = widget.providerName
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Container(
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initials,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineIndicator() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isOnline ? Colors.green : Colors.grey,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  String _getLastSeenText() {
    if (widget.isOnline) return 'Online';
    if (widget.lastSeen != null) {
      return 'Last seen ${timeago.format(widget.lastSeen!)}';
    }
    return '';
  }

  Widget _buildExperienceImages() {
    if (widget.experienceImages == null || widget.experienceImages!.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.experienceImages!.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: widget.experienceImages![index],
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _controller.forward();
                } else {
                  _controller.reverse();
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: widget.onViewProfile,
                            child: Hero(
                              tag: 'provider_avatar_${widget.providerId}',
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: widget.profileImage != null &&
                                          widget.profileImage!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: widget.profileImage!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.1),
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              _buildInitials(theme),
                                        )
                                      : _buildInitials(theme),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: _buildOnlineIndicator(),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.providerName,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (widget.isVerified)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.verified,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.message_outlined),
                                  onPressed: widget.onChat,
                                  tooltip: 'Send Message',
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                            if (widget.location != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.location!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _getLastSeenText(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: widget.isOnline
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Colors.amber[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.rating} (${widget.reviewCount})',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (widget.experienceImages != null &&
              widget.experienceImages!.isNotEmpty)
            _buildExperienceImages(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.skills.map((skill) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    skill,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.hourlyRate != null)
                        _buildDetailItem(
                          Icons.attach_money,
                          'Hourly Rate',
                          '₹${widget.hourlyRate}/hr',
                        ),
                      if (widget.education != null)
                        _buildDetailItem(
                          Icons.school_outlined,
                          'Education',
                          widget.education!,
                        ),
                      if (widget.experience != null)
                        _buildDetailItem(
                          Icons.work_outline,
                          'Experience',
                          widget.experience!,
                        ),
                      if (widget.certifications != null)
                        _buildDetailItem(
                          Icons.verified_outlined,
                          'Certifications',
                          widget.certifications!.join(', '),
                        ),
                      if (widget.languages != null)
                        _buildDetailItem(
                          Icons.language,
                          'Languages',
                          widget.languages!.join(', '),
                        ),
                      if (widget.availability != null)
                        _buildDetailItem(
                          Icons.access_time,
                          'Availability',
                          widget.availability!,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onViewProfile,
                          icon: const Icon(Icons.person_outline),
                          label: const Text('View Full Profile'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onPrimary,
                            backgroundColor: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onChat,
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            side: BorderSide(color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
