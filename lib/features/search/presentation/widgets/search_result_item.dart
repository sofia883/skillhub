import 'package:flutter/material.dart';
import 'package:skill_hub/features/home/domain/entities/skill.dart';

class SearchResultItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get location from skill or extract from description
    String location = skill.location ?? 'Location not available';

    // If location is not available, try to extract from description
    if (location == 'Location not available' &&
        skill.description.contains('Location:')) {
      final locationStart = skill.description.indexOf('Location:');
      final locationEnd = skill.description.indexOf('\n', locationStart);
      if (locationEnd > locationStart) {
        location =
            skill.description.substring(locationStart + 9, locationEnd).trim();
      } else {
        location = skill.description.substring(locationStart + 9).trim();
      }
    }

    return InkWell(
      onTap: onTap,
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
            // Skill image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                skill.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Skill details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Highlight the search query in the title
                  _buildHighlightedText(
                    skill.title,
                    searchQuery,
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
                      skill.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Location with icon
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Provider and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Provider
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor:
                                  theme.colorScheme.secondary.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 12,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                skill.provider,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                          '₹${skill.price.toStringAsFixed(0)}',
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
