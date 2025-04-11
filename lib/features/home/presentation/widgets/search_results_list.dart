import 'package:flutter/material.dart';
import '../../domain/entities/skill.dart';
import 'highlighted_text.dart';

class SearchResultsList extends StatelessWidget {
  final List<Skill> skills;
  final String searchQuery;
  final Function(Skill) onSkillTap;
  final bool isLoading;
  final bool showRelatedHeader;

  const SearchResultsList({
    super.key,
    required this.skills,
    required this.searchQuery,
    required this.onSkillTap,
    this.isLoading = false,
    this.showRelatedHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search results header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                showRelatedHeader
                    ? 'Related Results'
                    : 'Search Results for "$searchQuery"',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${skills.length} results',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: skills.length,
            itemBuilder: (context, index) {
              final skill = skills[index];
              return SearchResultItem(
                skill: skill,
                searchQuery: searchQuery,
                onTap: () => onSkillTap(skill),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SearchResultItem extends StatelessWidget {
  final Skill skill;
  final String searchQuery;
  final VoidCallback onTap;

  const SearchResultItem({
    super.key,
    required this.skill,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skill image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  skill.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Skill details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with highlighted search term
                    HighlightedText(
                      text: skill.title,
                      searchQuery: searchQuery,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      highlightStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                        backgroundColor: Colors.orange.withOpacity(0.1),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Category and price
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            skill.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹${skill.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Description with highlighted search term
                    HighlightedText(
                      text: skill.description,
                      searchQuery: searchQuery,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      highlightStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        backgroundColor: Colors.orange.withOpacity(0.1),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 4),

                    // Provider and rating
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: HighlightedText(
                            text: skill.provider,
                            searchQuery: searchQuery,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            highlightStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                              backgroundColor: Colors.orange.withOpacity(0.1),
                            ),
                            maxLines: 1,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              skill.rating.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Location (if available)
                    if (skill.location != null && skill.location!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: HighlightedText(
                                text: skill.location!,
                                searchQuery: searchQuery,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                highlightStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                  backgroundColor:
                                      Colors.orange.withOpacity(0.1),
                                ),
                                maxLines: 1,
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
        ),
      ),
    );
  }
}
