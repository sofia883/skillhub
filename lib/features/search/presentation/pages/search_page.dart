import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/home/domain/entities/skill.dart';
import '../../../../features/home/presentation/widgets/skill_card.dart';
import '../../../../features/home/data/repositories/skill_repository.dart';
import '../widgets/search_suggestions.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _skillRepository = SkillRepository();
  final _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _showHistory = true;
  List<Skill> _searchResults = [];
  Timer? _debounce;

  final List<String> categories = [
    'All',
    'Programming',
    'Design',
    'Marketing',
    'Writing',
    'Music',
    'Fitness',
    'Cooking',
    'Stitching',
    'Mehndi',
    'Photography',
    'Teaching',
    'Cleaning',
    'Tutoring',
    'Languages',
    'Handcrafts',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _showHistory = _searchController.text.isEmpty;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text.trim();
          _showHistory = _searchQuery.isEmpty;
        });
        if (!_showHistory) {
          _performSearch();
        }
      }
    });
  }

  void _onHistorySelected(String query) {
    _searchController.text = query;
    setState(() {
      _searchQuery = query;
      _showHistory = false;
    });
    _performSearch();
  }

  void _performSearch() {
    setState(() {
      _isLoading = true;
    });

    _skillRepository
        .searchSkills(_searchQuery, _selectedCategory)
        .then((results) {
      setState(() {
        // Filter out user's own listings and remove duplicates
        _searchResults = results
            .where((skill) => skill.userId != _currentUserId)
            .toSet()
            .toList();
        _isLoading = false;
      });
    }).catchError((error) {
      print('Error searching skills: $error');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    });
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);

    final matches = query
        .toLowerCase()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    List<TextSpan> spans = [];
    String remainingText = text;

    while (remainingText.isNotEmpty) {
      bool foundMatch = false;
      int earliestMatchIndex = remainingText.length;
      String matchedWord = '';

      for (final word in matches) {
        final index = remainingText.toLowerCase().indexOf(word);
        if (index != -1 && index < earliestMatchIndex) {
          earliestMatchIndex = index;
          matchedWord = remainingText.substring(index, index + word.length);
          foundMatch = true;
        }
      }

      if (foundMatch) {
        if (earliestMatchIndex > 0) {
          spans.add(TextSpan(
            text: remainingText.substring(0, earliestMatchIndex),
          ));
        }
        spans.add(TextSpan(
          text: matchedWord,
          style: const TextStyle(
            backgroundColor: Color(0x33FFB76B),
            fontWeight: FontWeight.bold,
          ),
        ));
        remainingText = remainingText.substring(
          earliestMatchIndex + matchedWord.length,
        );
      } else {
        spans.add(TextSpan(text: remainingText));
        break;
      }
    }

    return RichText(
        text: TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: spans,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Skills'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for skills or service providers',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _showHistory = true;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                setState(() => _showHistory = false);
                _performSearch();
              },
            ),
          ),

          // Category filter
          if (!_showHistory)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _performSearch();
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _selectedCategory == category
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondaryColor,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Results or History
          Expanded(
            child: _showHistory
                ? SearchHistory(
                    onHistorySelected: _onHistorySelected,
                  )
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final skill = _searchResults[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: SkillCard(
                                  skill: skill,
                                  titleWidget:
                                      _highlightText(skill.title, _searchQuery),
                                  descriptionWidget: _highlightText(
                                    skill.description ?? '',
                                    _searchQuery,
                                  ),
                                  onTap: () {
                                    // TODO: Navigate to skill detail screen
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Viewing ${skill.title}'),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? _selectedCategory == 'All'
                    ? 'No skills found'
                    : 'No skills found in $_selectedCategory category'
                : 'No skills matching "$_searchQuery"',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different search or be the first to add a skill',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
