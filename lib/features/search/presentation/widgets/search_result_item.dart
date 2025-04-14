import 'package:flutter/material.dart';
import 'package:skill_hub/features/home/domain/entities/skill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchResultItem extends StatefulWidget {
  final Skill skill;
  final VoidCallback? onTap;
  final String searchQuery;

  const SearchResultItem({
    super.key,
    required this.skill,
    required this.searchQuery,
    this.onTap,
  });

  @override
  State<SearchResultItem> createState() => _SearchResultItemState();
}

class _SearchResultItemState extends State<SearchResultItem> {
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

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          color: Colors.white,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        // Add subtle shadow for better visual hierarchy
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider profile image or initial
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

            // Skill details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Highlight the search query in the title
                  _buildHighlightedText(
                    widget.skill.title,
                    widget.searchQuery,
                    theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    theme.colorScheme.primary,
                  ),

                  const SizedBox(height: 4),

                  // Category
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.skill.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Provider name
                  Text(
                    widget.skill.provider,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Provider and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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

                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₹${widget.skill.price.toStringAsFixed(0)}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to highlight search query in text
  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle style,
    Color highlightColor,
  ) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    final List<TextSpan> spans = [];
    final String lowercaseText = text.toLowerCase();
    final String lowercaseQuery = query.toLowerCase();

    int start = 0;
    int indexOfQuery = lowercaseText.indexOf(lowercaseQuery);

    while (indexOfQuery != -1) {
      // Add text before the query
      if (indexOfQuery > start) {
        spans.add(TextSpan(
          text: text.substring(start, indexOfQuery),
          style: style,
        ));
      }

      // Add the highlighted query
      spans.add(TextSpan(
        text: text.substring(indexOfQuery, indexOfQuery + query.length),
        style: style.copyWith(
          backgroundColor: highlightColor.withOpacity(0.2),
          color: highlightColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      // Update start position for next iteration
      start = indexOfQuery + query.length;
      indexOfQuery = lowercaseText.indexOf(lowercaseQuery, start);
    }

    // Add any remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
