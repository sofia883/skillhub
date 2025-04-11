import 'package:flutter/material.dart';

class SearchSuggestions extends StatefulWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionTap;
  final VoidCallback onClearHistory;

  const SearchSuggestions({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
    required this.onClearHistory,
  });

  @override
  State<SearchSuggestions> createState() => _SearchSuggestionsState();
}

class _SearchSuggestionsState extends State<SearchSuggestions> {
  // Flag to track if history is expanded
  bool _isHistoryExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Start typing to search',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with clear button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                'Suggestions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (widget.suggestions.isNotEmpty)
                TextButton.icon(
                  onPressed: widget.onClearHistory,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),

        // Suggestions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: widget.suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = widget.suggestions[index];

              // This code was incorrect - we need to check if this is a history item
              // that should be hidden when not expanded

              // First, identify if this is a history item
              final recentIndex = widget.suggestions.indexOf('RECENT SEARCHES');
              final viewAllIndex =
                  widget.suggestions.indexOf('VIEW_ALL_HISTORY');
              final trendingIndex =
                  widget.suggestions.indexOf('TRENDING SEARCHES');

              // Check if this is a history item (between RECENT SEARCHES and either VIEW_ALL_HISTORY or TRENDING SEARCHES)
              final isHistoryItem = recentIndex != -1 &&
                  index > recentIndex &&
                  ((viewAllIndex != -1 && index < viewAllIndex) ||
                      (viewAllIndex == -1 &&
                          trendingIndex != -1 &&
                          index < trendingIndex));

              // If this is a history item and we're not expanded, check if it should be hidden
              if (isHistoryItem && !_isHistoryExpanded) {
                // Calculate position in history (0-based)
                final historyPosition = index - (recentIndex + 1);
                // Skip if beyond the first 5 items
                if (historyPosition >= 5) {
                  return const SizedBox.shrink();
                }
              }

              // Check if this is a View All button
              if (suggestion == 'VIEW_ALL_HISTORY') {
                return ListTile(
                  leading: Icon(
                    _isHistoryExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: const Color(0xFFFF9E80),
                  ),
                  title: Text(
                    _isHistoryExpanded ? 'Show Less' : 'View All History',
                    style: const TextStyle(
                      color: Color(0xFFFF9E80),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  dense: true,
                  onTap: () {
                    setState(() {
                      _isHistoryExpanded = !_isHistoryExpanded;
                    });
                  },
                );
              }

              // Check if this is a section header
              if (suggestion == 'RECENT SEARCHES' ||
                  suggestion == 'TRENDING SEARCHES' ||
                  suggestion == 'MATCHING HISTORY' ||
                  suggestion == 'MATCHING TRENDING' ||
                  suggestion == 'MATCHING CATEGORIES') {
                // Return a section header
                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        suggestion.contains('RECENT')
                            ? Icons.history
                            : suggestion.contains('TRENDING')
                                ? Icons.trending_up
                                : Icons.category,
                        size: 16,
                        color: suggestion.contains('RECENT')
                            ? theme.colorScheme.primary
                            : suggestion.contains('TRENDING')
                                ? Colors.orange
                                : theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        suggestion.replaceAll('_', ' '),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final isCategory = suggestion.startsWith('Category:');

              // Check if this is a trending search
              final isTrending = index > 0 &&
                  (widget.suggestions
                          .getRange(0, index)
                          .contains('TRENDING SEARCHES') ||
                      widget.suggestions
                          .getRange(0, index)
                          .contains('MATCHING TRENDING'));

              // Check if this is a recent search
              final isRecent = index > 0 &&
                  (widget.suggestions
                          .getRange(0, index)
                          .contains('RECENT SEARCHES') ||
                      widget.suggestions
                          .getRange(0, index)
                          .contains('MATCHING HISTORY'));

              return ListTile(
                leading: Icon(
                  isCategory
                      ? Icons.category
                      : isTrending
                          ? Icons.trending_up
                          : isRecent
                              ? Icons.history
                              : Icons.search,
                  size: 20,
                  color: isCategory
                      ? theme.colorScheme.secondary
                      : isTrending
                          ? Colors.orange
                          : isRecent
                              ? theme.colorScheme.primary.withOpacity(0.7)
                              : Colors.grey[600],
                ),
                title: Text(
                  isCategory ? suggestion.substring(10) : suggestion,
                  style: theme.textTheme.bodyMedium,
                ),
                dense: true,
                onTap: () => widget.onSuggestionTap(
                  isCategory ? suggestion.substring(10) : suggestion,
                ),
                trailing: Icon(
                  Icons.north_west,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
