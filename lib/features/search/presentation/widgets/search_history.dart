import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class SearchHistory extends StatefulWidget {
  final Function(String, {bool focusSearchBar}) onHistorySelected;
  final List<String> searchHistory;
  final List<String> trendingSearches;
  final String currentQuery;
  final VoidCallback onClearHistory;

  const SearchHistory({
    Key? key,
    required this.onHistorySelected,
    required this.searchHistory,
    required this.trendingSearches,
    required this.currentQuery,
    required this.onClearHistory,
  }) : super(key: key);

  @override
  State<SearchHistory> createState() => _SearchHistoryState();
}

class _SearchHistoryState extends State<SearchHistory> {
  bool _showAllHistory = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter history based on current query
    final filteredHistory = widget.currentQuery.isEmpty
        ? widget.searchHistory
        : widget.searchHistory
            .where((item) =>
                item.toLowerCase().contains(widget.currentQuery.toLowerCase()))
            .toList();

    // Filter trending based on current query
    final filteredTrending = widget.currentQuery.isEmpty
        ? widget.trendingSearches
        : widget.trendingSearches
            .where((item) =>
                item.toLowerCase().contains(widget.currentQuery.toLowerCase()))
            .toList();

    if (filteredHistory.isEmpty && filteredTrending.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayedSearches =
        _showAllHistory ? filteredHistory : filteredHistory.take(5).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filteredHistory.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onClearHistory,
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        color: Color(0xFFFF9E80),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedSearches.length +
                  (filteredHistory.length > 5 && !_showAllHistory ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == displayedSearches.length) {
                  return TextButton(
                    onPressed: () => setState(() => _showAllHistory = true),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFFFF9E80),
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                final search = displayedSearches[index];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(search),
                  onTap: () => widget.onHistorySelected(search),
                  dense: true,
                );
              },
            ),
          ],
          if (filteredTrending.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Trending Searches',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filteredTrending.map((trend) {
                  return ActionChip(
                    label: Text(trend),
                    onPressed: () => widget.onHistorySelected(trend),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: theme.colorScheme.primary,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
