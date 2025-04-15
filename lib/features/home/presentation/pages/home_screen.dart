import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/widgets/connectivity_status_indicator.dart';
import '../widgets/category_chip.dart';
import '../../domain/entities/skill.dart';
import '../../data/repositories/skill_repository.dart';
import '../../../../features/skills/presentation/pages/skill_detail_page.dart';
import '../../../../features/home/presentation/widgets/skill_list.dart';
import '../../../../features/search/presentation/widgets/search_results_list.dart';
import '../../../../features/search/presentation/widgets/search_history.dart';

class HomeScreen extends StatefulWidget {
  final bool initialSearchMode;

  const HomeScreen({
    super.key,
    this.initialSearchMode = false,
  });

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  bool _isLoading = true;
  bool _isSearching = false;
  bool _showingRelatedResults = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Flag to show search suggestions
  bool _showSearchSuggestions = false;

  // Search history (store recent searches)
  final List<String> _searchHistory = [];

  // Trending searches (popular searches)
  final List<String> _trendingSearches = [
    'Mehndi',
    'Wedding Photography',
    'Makeup Artist',
    'Cooking Classes',
    'Home Tutor',
    'Yoga Instructor',
    'Electrician',
    'Plumber',
  ];

  // Common words used in skill searches
  final List<String> _commonWords = [
    'skill', 'service', 'help', 'tutor', 'class', 'lesson', 'teacher',
    'expert', 'professional', 'home', 'online', 'local', 'best', 'cheap',
    'affordable', 'quality', 'top', 'rated', 'experienced', 'certified',
    'learn', 'hire', 'find', 'near', 'available', 'fast', 'reliable',
    'trusted', 'recommended', 'popular', 'trending', 'new', 'course',
    // Add common category words
    'programming', 'design', 'marketing', 'writing', 'music', 'fitness',
    'cooking', 'stitching', 'mehndi', 'photography', 'teaching', 'languages',
    'cleaning', 'repair', 'maintenance', 'installation', 'consultation',
    'coaching', 'training', 'development', 'support', 'assistance',
    // Add common skill-specific words
    'website', 'app', 'software', 'mobile', 'web', 'graphic', 'logo',
    'content', 'seo', 'social', 'media', 'blog', 'article', 'translation',
    'editing', 'proofreading', 'instrument', 'vocal', 'dance', 'yoga',
    'meditation', 'nutrition', 'recipe', 'baking', 'cooking', 'embroidery',
    'wedding', 'portrait', 'event', 'math', 'science', 'english', 'hindi',
    'spanish', 'french', 'german', 'chinese', 'japanese', 'arabic',
  ];

  // Check if a query contains any common words or is a valid search
  bool _containsCommonWords(String query) {
    // If query is very short, it's probably not random text
    if (query.length <= 3) {
      return true;
    }

    // Split query into words
    final words = query.toLowerCase().split(RegExp(r'\s+'));

    // If any word is very short, it's probably not random text
    for (final word in words) {
      if (word.length <= 2) {
        return true;
      }
    }

    // Check if query contains any common words
    final lowerQuery = query.toLowerCase();
    for (final word in _commonWords) {
      if (lowerQuery.contains(word)) {
        return true;
      }
    }

    // Check if query has a reasonable character distribution
    // Random text often has unusual character patterns
    final letterCounts = <String, int>{};
    for (int i = 0; i < lowerQuery.length; i++) {
      final char = lowerQuery[i];
      letterCounts[char] = (letterCounts[char] ?? 0) + 1;
    }

    // If any letter appears more than 25% of the time, it might be random text
    final maxCount =
        letterCounts.values.fold(0, (max, count) => count > max ? count : max);
    if (maxCount > lowerQuery.length * 0.25 && lowerQuery.length > 4) {
      return false;
    }

    // If query has more than 2 consecutive consonants, it's probably random text
    if (lowerQuery.contains(RegExp(r'[bcdfghjklmnpqrstvwxyz]{3,}'))) {
      return false;
    }

    // Count vowels and consonants
    int vowels = 0;
    int consonants = 0;
    for (int i = 0; i < lowerQuery.length; i++) {
      final char = lowerQuery[i];
      if ('aeiou'.contains(char)) {
        vowels++;
      } else if ('bcdfghjklmnpqrstvwxyz'.contains(char)) {
        consonants++;
      }
    }

    // If the ratio of consonants to vowels is too high, it's probably random text
    if (vowels > 0 && consonants / vowels > 3) {
      return false;
    }

    // If we get here, we're not sure if it's random text or not
    // For queries longer than 5 characters with no common words, assume it's random
    return query.length <= 5;
  }

  // Connectivity status
  ConnectivityStatus _connectivityStatus = ConnectivityStatus.unknown;
  bool _isCheckingConnectivity = false;
  final ConnectivityService _connectivityService = ConnectivityService();

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
    'Languages',
    'Other',
  ];

  // Repository for skills
  final _skillRepository = SkillRepository();

  // Skills list
  List<Skill> _filteredSkills = [];

  // Load search history from SharedPreferences
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('search_history');
      if (historyJson != null) {
        setState(() {
          _searchHistory.clear();
          _searchHistory.addAll(historyJson);
        });
        debugPrint('Loaded ${_searchHistory.length} search history items');
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  // Save search history to SharedPreferences
  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', _searchHistory);
      debugPrint('Saved ${_searchHistory.length} search history items');
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize search mode based on parameter
    _isSearching = widget.initialSearchMode;

    // Make sure we start with the "All" category selected
    _selectedCategory = 'All';

    // Load search history from SharedPreferences
    _loadSearchHistory();

    _checkConnectivity();

    // Immediately load skills from cache and update UI
    _loadSkills(forceRefresh: false);

    // Then refresh from Firestore in the background
    if (mounted) {
      // Use a microtask to run this after the current frame is rendered
      Future.microtask(() {
        _loadSkills(forceRefresh: true);
      });
    }

    _searchController.addListener(_onSearchChanged);

    // Listen for connectivity changes
    _connectivityService.connectivityStream.listen((status) {
      setState(() {
        _connectivityStatus = status;
        if (status == ConnectivityStatus.online) {
          // Refresh data when coming back online
          _loadSkills(forceRefresh: true);
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Immediately load skills from cache and update UI
    _loadSkills(forceRefresh: false);

    // Then refresh from Firestore in the background
    if (mounted) {
      // Use a microtask to run this after the current frame is rendered
      Future.microtask(() {
        _loadSkills(forceRefresh: true);
        debugPrint('Skills refreshed after navigation');
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Check connectivity status
  Future<void> _checkConnectivity() async {
    setState(() {
      _isCheckingConnectivity = true;
    });

    final status = await _connectivityService.checkConnectivity();

    if (mounted) {
      setState(() {
        _connectivityStatus = status;
        _isCheckingConnectivity = false;
      });
    }
  }

  Future<void> _loadSkills({bool forceRefresh = false}) async {
    if (_isLoading && forceRefresh == false) {
      return; // Prevent multiple concurrent loads
    }

    try {
      debugPrint('Loading skills with forceRefresh: $forceRefresh');
      final skills = await _skillRepository.getSkills(
          forceRefresh: forceRefresh, excludeCurrentUser: true);

      if (mounted) {
        // Remove duplicates by ID
        final Map<String, Skill> uniqueSkills = {};
        for (final skill in skills) {
          uniqueSkills[skill.id] = skill;
        }
        final uniqueSkillsList = uniqueSkills.values.toList();

        setState(() {
          if (_isSearching) {
            // If searching, keep filtered skills
            _filteredSkills = _filteredSkills;
          } else {
            // If not searching, show all skills based on category
            _filteredSkills = _selectedCategory == 'All'
                ? uniqueSkillsList
                : uniqueSkillsList
                    .where((skill) => skill.category == _selectedCategory)
                    .toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading skills: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _isSearching = true;
      _showSearchSuggestions = true;
    });

    // If the search field is empty, show full search history
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredSkills = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      setState(() {
        _searchQuery = query;
        _showSearchSuggestions = true; // Keep showing suggestions while typing
        _isSearching = true;
      });
      _performSearch();
    });
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredSkills = [];
        _isLoading = false;
        _showSearchSuggestions = true;
        _showingRelatedResults = false;
      });
      return;
    }

    // Don't perform search if it's already showing related results
    if (_searchQuery.startsWith('Related to:')) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Get all skills from local cache
    final cachedSkills = _skillRepository.getAllSkills();
    final lowerQuery = _searchQuery.toLowerCase();

    // Filter skills
    final filtered = cachedSkills.where((skill) {
      return skill.title.toLowerCase().contains(lowerQuery) ||
          skill.description.toLowerCase().contains(lowerQuery) ||
          skill.provider.toLowerCase().contains(lowerQuery) ||
          skill.category.toLowerCase().contains(lowerQuery) ||
          (skill.location != null &&
              skill.location!.toLowerCase().contains(lowerQuery));
    }).toList();

    setState(() {
      _filteredSkills = filtered;
      _isLoading = false;
      _showSearchSuggestions = false;
      _showingRelatedResults = false;
    });

    // Show a snackbar with the number of results
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No results found for "$_searchQuery"'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addToSearchHistory(String query) {
    if (query.isEmpty || query.length <= 2 || query.startsWith('Related to:')) {
      return;
    }

    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
      _saveSearchHistory();
    }
  }

  void _onSearchIconPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          initialSearchMode: true,
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _showSearchSuggestions = true;
    });
  }

  void _handleBackPress() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _showingRelatedResults = false;
      _showSearchSuggestions = false;
      _selectedCategory = 'All';
      _filteredSkills = [];
    });
    // Load all skills again to show normal home screen
    Future.microtask(() {
      if (mounted) {
        _loadSkills(forceRefresh: true);
      }
    });
  }

  // Clear search history
  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
      // Refresh suggestions to show only trending searches
      if (_showSearchSuggestions) {
        // Keep showing suggestions, but now only trending searches will be shown
        _showSearchSuggestions = true;
      }
    });

    // Save empty search history to SharedPreferences
    _saveSearchHistory();

    // Show a snackbar to confirm
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Search history cleared'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Handle skill tap
  void _onSkillTap(Skill skill) {
    debugPrint('Skill tapped: ${skill.title}, search query: $_searchQuery');

    // Navigate to the detail page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SkillDetailPage(skill: skill),
      ),
    );
  }

  // Show related skills based on the selected skill
  void _showRelatedSkills(Skill selectedSkill) {
    setState(() {
      _isLoading = true;
    });

    // Get all skills from local cache immediately
    final allSkills = _skillRepository.getAllSkills();

    // Create a map to store skills with their relevance score
    final Map<Skill, int> skillScores = {};

    // Calculate relevance score for each skill
    for (final skill in allSkills) {
      // Don't include the selected skill
      if (skill.id == selectedSkill.id) continue;

      int score = 0;

      // Same category is highly relevant
      if (skill.category == selectedSkill.category) {
        score += 20;
      }

      // Same provider is relevant
      if (skill.provider == selectedSkill.provider) {
        score += 15;
      }

      // Similar price range (within 20% of selected skill's price)
      final priceRatio = skill.price / selectedSkill.price;
      if (priceRatio >= 0.8 && priceRatio <= 1.2) {
        score += 10;
      }

      // Similar title (contains any word from selected skill's title)
      final selectedTitleWords = selectedSkill.title
          .toLowerCase()
          .split(' ')
          .where((word) => word.length > 3)
          .toList();

      final skillTitle = skill.title.toLowerCase();
      for (final word in selectedTitleWords) {
        if (skillTitle.contains(word)) {
          score += 5;
        }
      }

      // Only include skills with a score above 0
      if (score > 0) {
        skillScores[skill] = score;
      }
    }

    // Convert map to list and sort by score (highest first)
    final relatedSkills = skillScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Extract just the skills from the sorted entries
    final sortedSkills = relatedSkills.map((entry) => entry.key).toList();

    // Remove duplicates by ID
    final Map<String, Skill> uniqueSkills = {};
    for (final skill in sortedSkills) {
      uniqueSkills[skill.id] = skill;
    }
    final uniqueSortedSkills = uniqueSkills.values.toList();

    setState(() {
      _filteredSkills = uniqueSortedSkills;
      _isLoading = false;
      _showingRelatedResults = uniqueSortedSkills.isNotEmpty;
      // Update search query to show what we're showing related results for
      _searchQuery = 'Related to: ${selectedSkill.title}';
      _isSearching = true; // Ensure we're in search mode
    });

    if (uniqueSortedSkills.isEmpty) {
      debugPrint('No related skills found for: ${selectedSkill.title}');
    } else {
      debugPrint(
          'Found ${uniqueSortedSkills.length} related skills for: ${selectedSkill.title}');
      // Log the top 3 results with their scores for debugging
      for (int i = 0;
          i < (relatedSkills.length > 3 ? 3 : relatedSkills.length);
          i++) {
        final entry = relatedSkills[i];
        debugPrint('  ${i + 1}. ${entry.key.title} (Score: ${entry.value})');
      }
    }
  }

  void _onHistorySelected(String query) {
    _searchController.text = query;
    setState(() {
      _searchQuery = query;
      _showSearchSuggestions = false;
      _isSearching = true;
    });
    _performSearch();
  }

  // Add a new button to show related results
  Widget _buildShowRelatedButton(Skill skill) {
    return TextButton.icon(
      onPressed: () => _showRelatedSkills(skill),
      icon: const Icon(Icons.auto_awesome),
      label: const Text('Show Similar Skills'),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Clear navigation history when reaching home screen (not in search mode)
    if (!_isSearching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isSearching) {
          Navigator.of(context).pop();
          return false;
        }

        // Always show exit dialog on home screen
        return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit App'),
                content: const Text('Are you sure you want to exit?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      child: RefreshIndicator(
        onRefresh: () => _loadSkills(forceRefresh: true),
        child: Scaffold(
          appBar: AppBar(
            leading: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
            title: _isSearching
                ? Container(
                    height: 48,
                    width: double.infinity,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                          color: Colors.grey.withOpacity(0.2), width: 1),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search skills, categories, providers...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.only(left: 12, right: 8),
                          child: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFFFF9E80),
                            size: 24,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? Container(
                                margin: const EdgeInsets.only(right: 12),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Icon(
                                      Icons.clear_rounded,
                                      color: Colors.grey[500],
                                      size: 20,
                                    ),
                                    onTap: _clearSearch,
                                  ),
                                ),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                      ),
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      onTap: () {
                        setState(() {
                          _isSearching = true;
                          _showSearchSuggestions = true;
                          _filteredSkills = [];
                        });
                      },
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _addToSearchHistory(value.trim());
                          setState(() {
                            _searchQuery = value.trim();
                            _showSearchSuggestions = false;
                          });
                          _performSearch();
                        }
                      },
                    ),
                  )
                : const Text('Skill Hub'),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                tooltip: _isSearching ? 'Close Search' : 'Search Skills',
                onPressed: _isSearching
                    ? () => Navigator.of(context).pop()
                    : _onSearchIconPressed,
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  const ConnectivityStatusIndicator(),
                  if (!_isSearching) _buildCategoryFilter(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _isSearching
                        ? (_showSearchSuggestions
                            ? SearchHistory(
                                searchHistory: _searchHistory,
                                trendingSearches: _trendingSearches,
                                currentQuery: _searchController.text,
                                onHistorySelected: _onHistorySelected,
                                onClearHistory: _clearSearchHistory,
                              )
                            : SearchResultsList(
                                skills: _filteredSkills,
                                searchQuery: _searchQuery,
                                onSkillTap: _onSkillTap,
                                isLoading: _isLoading,
                                showRelatedHeader: _showingRelatedResults,
                              ))
                        : (_filteredSkills.isEmpty
                            ? _buildEmptyState()
                            : SkillList(
                                skills: _filteredSkills,
                                onSkillTap: _onSkillTap,
                              )),
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.1),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CategoryChip(
              label: category,
              isSelected: _selectedCategory == category,
              onSelected: (selected) {
                debugPrint('Category selected: $category');
                setState(() {
                  _selectedCategory = category;
                });
                // Immediately load and filter skills
                _loadSkills(forceRefresh: false);

                // Also force a refresh from Firestore in the background
                if (mounted) {
                  Future.microtask(() {
                    _loadSkills(forceRefresh: true);
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    // If we're checking connectivity, show loading
    if (_isCheckingConnectivity) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Checking connection...',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    // If we're offline, show offline message
    if (_connectivityStatus == ConnectivityStatus.offline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No Internet Connection',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Working in offline mode. Your skills are being saved locally.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _checkConnectivity();
                _loadSkills(forceRefresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // If we're searching, show no search results message
    if (_isSearching && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.orange.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF7043), // Deeper Orange
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _searchQuery.length > 10 && !_containsCommonWords(_searchQuery)
                    ? 'Your search text doesn\'t match any skills. Try using more common words.'
                    : 'No skills matching "$_searchQuery" were found.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9E80), // Pastel Orange
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Otherwise, show empty state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Skills Found',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _selectedCategory == 'All'
                  ? 'No skills available yet. Be the first to add a skill!'
                  : 'No skills found in the "$_selectedCategory" category.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadSkills(forceRefresh: true),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
