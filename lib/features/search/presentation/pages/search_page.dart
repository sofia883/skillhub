import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/home/domain/entities/skill.dart';
import '../../../../features/home/presentation/widgets/skill_card.dart';
import '../../../../features/home/data/repositories/skill_repository.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _skillRepository = SkillRepository();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = false;
  List<Skill> _allSkills = [];
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
    _loadSkills();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final skills = await _skillRepository.getSkills();
      setState(() {
        _allSkills = skills;
        _isLoading = false;
      });
      // Initial search to show all results
      _performSearch();
    } catch (e) {
      print('Error loading skills: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text.trim();
        });
        _performSearch();
      }
    });
  }

  void _performSearch() {
    setState(() {
      _isLoading = true;
    });

    // Use the repository's searchSkills method for better performance
    _skillRepository
        .searchSkills(_searchQuery, _selectedCategory)
        .then((results) {
      setState(() {
        _searchResults = results;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
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
                        });
                        _performSearch();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 16),

                // Category filter
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
              ],
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
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
                              onTap: () {
                                // TODO: Navigate to skill detail screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Viewing ${skill.title}')),
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
