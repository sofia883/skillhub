import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class SearchHistory extends StatefulWidget {
  final Function(String) onHistorySelected;

  const SearchHistory({
    Key? key,
    required this.onHistorySelected,
  }) : super(key: key);

  @override
  State<SearchHistory> createState() => _SearchHistoryState();
}

class _SearchHistoryState extends State<SearchHistory> {
  static const _recentSearchesKey = 'recent_searches';
  List<String> _recentSearches = [];
  bool _showAllHistory = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_recentSearchesKey) ?? [];

    // Remove if exists and add to front
    searches.remove(query);
    searches.insert(0, query);

    await prefs.setStringList(_recentSearchesKey, searches);
    setState(() {
      _recentSearches = searches;
    });
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    setState(() {
      _recentSearches = [];
    });
  }

  void _onHistoryTap(String query) {
    _saveRecentSearch(query);
    widget.onHistorySelected(query);
  }

  @override
  Widget build(BuildContext context) {
    if (_recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayedSearches =
        _showAllHistory ? _recentSearches : _recentSearches.take(7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                onPressed: _clearRecentSearches,
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
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
              (_recentSearches.length > 7 && !_showAllHistory ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == displayedSearches.length) {
              return TextButton(
                onPressed: () => setState(() => _showAllHistory = true),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                  ),
                ),
              );
            }

            final search = displayedSearches[index];
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(search),
              onTap: () => _onHistoryTap(search),
              dense: true,
            );
          },
        ),
      ],
    );
  }
}
