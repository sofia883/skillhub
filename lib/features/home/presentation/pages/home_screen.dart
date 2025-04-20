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
import 'package:country_state_city_picker/country_state_city_picker.dart';
import '../../../../core/widgets/enhanced_csc_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../../../features/profile/presentation/pages/profile_page.dart';

class HomeScreen extends StatefulWidget {
  final bool initialSearchMode;
  final bool isRoot;

  const HomeScreen({
    super.key,
    this.initialSearchMode = false,
    this.isRoot = true,
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

  // Filter states
  RangeValues _priceRange = const RangeValues(0, 10000);
  String? _selectedFilterCategory;
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  bool _showNearbyOnly = false;
  double _nearbyRadius = 10.0; // in kilometers
  String _selectedCurrency = '₹'; // Default to INR
  String? _userLocation;

  // Currency options
  final List<Map<String, String>> _currencies = [
    {'symbol': '₹', 'name': 'INR'},
    {'symbol': '\$', 'name': 'USD'},
    {'symbol': '€', 'name': 'EUR'},
    {'symbol': '£', 'name': 'GBP'},
  ];

  // Original search results before filtering
  List<Skill> _originalSearchResults = [];

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

    _getCurrentLocation();
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
        _originalSearchResults = [];
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
      _originalSearchResults = filtered;
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
          isRoot: false,
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

  void _onHistorySelected(String query, {bool focusSearchBar = false}) {
    setState(() {
      _searchQuery = query;
      _showSearchSuggestions = false;
      _isSearching = true;
    });

    if (focusSearchBar) {
      _searchController.text = query;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    } else {
      _searchController.text = query;
      _addToSearchHistory(query);
      _performSearch();
    }
  }

  // Add a new button to show related results
  Widget _buildShowRelatedButton(Skill skill) {
    return TextButton.icon(
      onPressed: () => _showRelatedSkills(skill),
      icon: const Icon(Icons.auto_awesome),
      label: const Text('Show Similar Skills'),
    );
  }

  Future<bool> _showExitDialog() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSearching) {
          Navigator.of(context).pop();
          return false;
        }
        if (widget.isRoot) {
          return _showExitDialog();
        }
        return true;
      },
      child: RefreshIndicator(
        onRefresh: () => _loadSkills(forceRefresh: true),
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            title: _isSearching
                ? _buildSearchField()
                : Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfilePage(),
                            ),
                          );
                        },
                        child: Hero(
                          tag: 'profile_avatar',
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                'https://via.placeholder.com/32',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  child: Icon(
                                    Icons.person,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSearching = true;
                            });
                          },
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Search',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.chat_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          // Navigate to messages
                        },
                      ),
                    ],
                  ),
          ),
          body: Column(
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
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  iconSize: 20,
                  onPressed: _clearSearch,
                )
              : null,
        ),
        style: const TextStyle(fontSize: 14),
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => WillPopScope(
          onWillPop: () async {
            // Reset filters when dialog is closed by back button
            setModalState(() {
              setState(() {
                _resetFilters();
              });
            });
            return true;
          },
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          // Reset filters when dialog is closed by X button
                          setModalState(() {
                            setState(() {
                              _resetFilters();
                            });
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Filter
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedFilterCategory,
                            isExpanded: true,
                            hint: const Text('Select Category'),
                            underline: const SizedBox(),
                            items: categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setModalState(() {
                                setState(() {
                                  _selectedFilterCategory = value;
                                });
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Price Range Filter with Currency
                        Row(
                          children: [
                            const Text(
                              'Price Range',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedCurrency,
                                underline: const SizedBox(),
                                items: _currencies.map((currency) {
                                  return DropdownMenuItem(
                                    value: currency['symbol'],
                                    child: Text(
                                        '${currency['symbol']} ${currency['name']}'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setModalState(() {
                                    setState(() {
                                      _selectedCurrency = value!;
                                    });
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 10000,
                          divisions: 100,
                          labels: RangeLabels(
                            '$_selectedCurrency${_priceRange.start.round()}',
                            '$_selectedCurrency${_priceRange.end.round()}',
                          ),
                          onChanged: (values) {
                            setModalState(() {
                              setState(() {
                                _priceRange = values;
                              });
                              _applyFilters();
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '$_selectedCurrency${_priceRange.start.round()}'),
                            Text(
                                '$_selectedCurrency${_priceRange.end.round()}'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Location Filter with CSC Picker
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: EnhancedCSCPicker(
                            selectedCountry: _selectedCountry,
                            selectedState: _selectedState,
                            selectedCity: _selectedCity,
                            onCountryChanged: (value) {
                              setModalState(() {
                                setState(() {
                                  _selectedCountry = value;
                                  _selectedState = null;
                                  _selectedCity = null;
                                });
                                _applyFilters();
                              });
                            },
                            onStateChanged: (value) {
                              if (value.startsWith("No states")) {
                                setModalState(() {
                                  setState(() {
                                    _selectedState = _selectedCountry;
                                    _selectedCity = null;
                                  });
                                  _applyFilters();
                                });
                                return;
                              }
                              setModalState(() {
                                setState(() {
                                  _selectedState = value;
                                  _selectedCity = null;
                                });
                                _applyFilters();
                              });
                            },
                            onCityChanged: (value) {
                              if (value.startsWith("No cities")) {
                                setModalState(() {
                                  setState(() {
                                    _selectedCity = _selectedState;
                                  });
                                  _applyFilters();
                                });
                                return;
                              }
                              setModalState(() {
                                setState(() {
                                  _selectedCity = value;
                                });
                                _applyFilters();
                              });
                            },
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Nearby Filter with Location Display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Show Nearby Skills',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: _showNearbyOnly,
                                    activeColor: const Color(0xFFFF9E80),
                                    onChanged: (value) {
                                      setModalState(() {
                                        setState(() {
                                          _showNearbyOnly = value;
                                        });
                                        _applyFilters();
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (_selectedCity != null &&
                                  _selectedState != null &&
                                  _selectedCountry != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.home_rounded,
                                      size: 20,
                                      color: Color(0xFFFF9E80),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_selectedCity}, ${_selectedState}, ${_selectedCountry}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Apply and Reset Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setModalState(() {
                                    setState(() {
                                      _resetFilters();
                                    });
                                  });
                                  // Don't close the dialog
                                },
                                child: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _applyFilters();
                                  Navigator.pop(context);
                                },
                                child: const Text('Apply'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    if (_originalSearchResults.isEmpty) return;

    List<Skill> filteredResults = List.from(_originalSearchResults);

    // Apply category filter
    if (_selectedFilterCategory != null && _selectedFilterCategory != 'All') {
      filteredResults = filteredResults
          .where((skill) => skill.category == _selectedFilterCategory)
          .toList();
    }

    // Apply price range filter
    filteredResults = filteredResults.where((skill) {
      if (skill.price == 0) return true; // Handle "Contact for Price" case

      // Convert price based on currency
      double convertedPrice = skill.price;
      // TODO: Implement actual currency conversion

      return convertedPrice >= _priceRange.start &&
          convertedPrice <= _priceRange.end;
    }).toList();

    // Apply location filter
    if (_selectedCountry != null) {
      filteredResults = filteredResults.where((skill) {
        if (skill.location == null) return false;

        bool matchesCountry = skill.location!
            .toLowerCase()
            .contains(_selectedCountry!.toLowerCase());

        if (!matchesCountry) return false;

        if (_selectedState != null &&
            !_selectedState!.startsWith('No states')) {
          bool matchesState = skill.location!
              .toLowerCase()
              .contains(_selectedState!.toLowerCase());
          if (!matchesState) return false;

          if (_selectedCity != null &&
              !_selectedCity!.startsWith('No cities')) {
            return skill.location!
                .toLowerCase()
                .contains(_selectedCity!.toLowerCase());
          }
        }
        return true;
      }).toList();
    }

    // Apply nearby filter
    if (_showNearbyOnly && _userLocation != null) {
      // TODO: Implement nearby filtering using user's location
      // This will require getting user's location and calculating distance
      filteredResults = filteredResults.where((skill) {
        if (skill.location == null) return false;
        return skill.location!
            .toLowerCase()
            .contains(_userLocation!.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredSkills = filteredResults;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final location = userDoc.data()?['location'] as String?;
          if (location != null) {
            final parts = location.split(', ');
            if (parts.length >= 3) {
              setState(() {
                _userLocation =
                    '${parts[0]}, ${parts[1]}, ${parts[2]}'; // City, State, Country format
                _selectedCity = parts[0]; // City
                _selectedState = parts[1]; // State
                _selectedCountry = parts[2]; // Country
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  // Add this new method to handle filter reset
  void _resetFilters() {
    _selectedFilterCategory = null;
    _priceRange = const RangeValues(0, 10000);
    _selectedCountry = null;
    _selectedState = null;
    _selectedCity = null;
    _showNearbyOnly = false;
    _nearbyRadius = 10.0;
    _selectedCurrency = '₹';

    // Force the CSC picker to reset
    if (mounted) {
      Future.microtask(() {
        setState(() {
          // This will trigger a rebuild of the CSC picker
          _selectedCountry = null;
        });
      });
    }

    _applyFilters();
  }
}
