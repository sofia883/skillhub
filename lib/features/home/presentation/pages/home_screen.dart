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
import '../../../../features/search/presentation/widgets/search_suggestions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  bool _isLoading = true;
  bool _isSearching = false;
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
      // Always force refresh from Firestore to get the latest data
      debugPrint('Loading skills with forceRefresh: $forceRefresh');
      final skills = await _skillRepository.getSkills(
          forceRefresh: forceRefresh,
          excludeCurrentUser:
              true // Add this parameter to exclude current user's listings
          );

      if (mounted) {
        // Remove duplicates by ID
        final Map<String, Skill> uniqueSkills = {};
        for (final skill in skills) {
          uniqueSkills[skill.id] = skill;
        }
        final uniqueSkillsList = uniqueSkills.values.toList();

        // Apply filters and update UI
        setState(() {
          _filteredSkills = _selectedCategory == 'All'
              ? uniqueSkillsList
              : uniqueSkillsList
                  .where((skill) => skill.category == _selectedCategory)
                  .toList();
          _isLoading = false;
        });
        debugPrint(
            'Skills loaded and filtered successfully: ${_filteredSkills.length} skills');
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

    // If the search field is empty, show search suggestions
    if (_searchController.text.isEmpty) {
      setState(() {
        _showSearchSuggestions = true;
        _isSearching = true; // Ensure search mode is active
        _filteredSkills = []; // Clear any previous results
      });
    } else {
      // If typing, hide search suggestions and show results immediately
      final query = _searchController.text.trim();
      setState(() {
        _showSearchSuggestions = false;
        _isSearching = true;
        _searchQuery = query;
        _isLoading = true; // Show brief loading indicator
      });

      // Get all skills from local cache
      final cachedSkills = _skillRepository.getAllSkills();
      final lowerQuery = query.toLowerCase();

      // Split the query into individual characters
      final queryChars = lowerQuery.split('');

      // Filter skills immediately
      final filtered = cachedSkills.where((skill) {
        // Check if the skill contains the full query
        final titleContains = skill.title.toLowerCase().contains(lowerQuery);
        final descContains =
            skill.description.toLowerCase().contains(lowerQuery);
        final providerContains =
            skill.provider.toLowerCase().contains(lowerQuery);
        final categoryContains =
            skill.category.toLowerCase().contains(lowerQuery);
        final locationContains = skill.location != null &&
            skill.location!.toLowerCase().contains(lowerQuery);

        // If any field contains the full query, include it
        if (titleContains ||
            descContains ||
            providerContains ||
            categoryContains ||
            locationContains) {
          return true;
        }

        // If the query is more than one character, check if it contains individual characters
        if (queryChars.length > 1) {
          // Count how many characters from the query are found in each field
          int matchCount = 0;
          final lowerTitle = skill.title.toLowerCase();
          final lowerDesc = skill.description.toLowerCase();
          final lowerProvider = skill.provider.toLowerCase();
          final lowerCategory = skill.category.toLowerCase();
          final lowerLocation = skill.location?.toLowerCase() ?? '';

          // Check each character
          for (final char in queryChars) {
            if (lowerTitle.contains(char) ||
                lowerDesc.contains(char) ||
                lowerProvider.contains(char) ||
                lowerCategory.contains(char) ||
                lowerLocation.contains(char)) {
              matchCount++;
            }
          }

          // If at least half of the characters match, include it
          return matchCount >= (queryChars.length / 2).ceil();
        }

        // For single character queries, we already checked above
        return false;
      }).toList();

      // Sort results by relevance
      filtered.sort((a, b) {
        // First, check for exact matches in title
        final aTitle = a.title.toLowerCase().contains(lowerQuery);
        final bTitle = b.title.toLowerCase().contains(lowerQuery);
        if (aTitle && !bTitle) {
          return -1;
        }
        if (!aTitle && bTitle) {
          return 1;
        }

        // Then check for exact matches in category
        final aCategory = a.category.toLowerCase().contains(lowerQuery);
        final bCategory = b.category.toLowerCase().contains(lowerQuery);
        if (aCategory && !bCategory) {
          return -1;
        }
        if (!aCategory && bCategory) {
          return 1;
        }

        // If query has multiple characters, calculate match score for each skill
        if (queryChars.length > 1) {
          // Calculate match score for skill A
          int aScore = 0;
          final aLowerTitle = a.title.toLowerCase();
          final aLowerDesc = a.description.toLowerCase();
          final aLowerProvider = a.provider.toLowerCase();
          final aLowerCategory = a.category.toLowerCase();
          final aLowerLocation = a.location?.toLowerCase() ?? '';

          // Calculate match score for skill B
          int bScore = 0;
          final bLowerTitle = b.title.toLowerCase();
          final bLowerDesc = b.description.toLowerCase();
          final bLowerProvider = b.provider.toLowerCase();
          final bLowerCategory = b.category.toLowerCase();
          final bLowerLocation = b.location?.toLowerCase() ?? '';

          // Check each character
          for (final char in queryChars) {
            // Add to score A
            if (aLowerTitle.contains(char)) {
              aScore += 3; // Title matches are most important
            }
            if (aLowerCategory.contains(char)) {
              aScore += 2; // Category matches are next
            }
            if (aLowerDesc.contains(char)) {
              aScore += 1;
            }
            if (aLowerProvider.contains(char)) {
              aScore += 1;
            }
            if (aLowerLocation.contains(char)) {
              aScore += 1;
            }

            // Add to score B
            if (bLowerTitle.contains(char)) {
              bScore += 3;
            }
            if (bLowerCategory.contains(char)) {
              bScore += 2;
            }
            if (bLowerDesc.contains(char)) {
              bScore += 1;
            }
            if (bLowerProvider.contains(char)) {
              bScore += 1;
            }
            if (bLowerLocation.contains(char)) {
              bScore += 1;
            }
          }

          // Sort by score (higher score first)
          if (aScore != bScore) {
            return bScore - aScore; // Higher score first
          }
        }

        // If scores are equal or we have a single character query, sort by creation date
        return b.createdAt.compareTo(a.createdAt);
      });

      // Update UI with filtered skills
      setState(() {
        _filteredSkills = filtered;
        _isLoading = false;
        _showingRelatedResults = false;
      });
    }

    // We don't need the debounce timer anymore since we're filtering immediately
    // But we'll keep a short debounce to avoid too many updates for fast typing
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // Just a safety check to make sure UI is updated with the latest query
      if (_searchController.text != _searchQuery) {
        final newQuery = _searchController.text.trim();
        setState(() {
          _searchQuery = newQuery;
          _isSearching = true;
        });

        if (newQuery.isNotEmpty) {
          _filterSkills();
        } else {
          // If search is cleared, show search suggestions
          setState(() {
            _showSearchSuggestions = true;
          });
          _loadSkills(forceRefresh: false);
        }
      }
    });
  }

  // Get search suggestions based on current input
  List<String> _getSearchSuggestions() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      // If no query, return recent searches and trending searches
      final List<String> suggestions = [];

      // Add recent searches with a label
      if (_searchHistory.isNotEmpty) {
        suggestions
            .add('RECENT SEARCHES'); // This will be handled specially in the UI

        // Add all history items (the SearchSuggestions widget will handle showing only the first 5)
        suggestions.addAll(_searchHistory);

        // Add View All button if there are more than 5 items
        if (_searchHistory.length > 5) {
          suggestions
              .add('VIEW_ALL_HISTORY'); // Special marker for View All button
        }
      }

      // Add trending searches with a label
      suggestions
          .add('TRENDING SEARCHES'); // This will be handled specially in the UI
      suggestions.addAll(_trendingSearches);

      return suggestions;
    }

    // If there's a query, combine all matching items without section headers
    List<String> filteredSuggestions = [];

    // Filter search history for matching items
    final historySuggestions = _searchHistory
        .where((term) => term.toLowerCase().contains(query))
        .toList();
    filteredSuggestions.addAll(historySuggestions);

    // Filter trending searches for matching items
    final trendingSuggestions = _trendingSearches
        .where((term) => term.toLowerCase().contains(query))
        .toList();
    filteredSuggestions.addAll(trendingSuggestions);

    // Get category suggestions
    final categorySuggestions = categories
        .where((category) =>
            category.toLowerCase().contains(query) && category != 'All')
        .toList();
    filteredSuggestions
        .addAll(categorySuggestions.map((cat) => 'Category: $cat'));

    return filteredSuggestions;
  }

  void _filterSkills() {
    debugPrint(
        'Filtering skills for category: $_selectedCategory, search: $_searchQuery');

    // Show a brief loading indicator
    setState(() {
      _isLoading = true;
    });

    // First check if we have skills in local cache
    final cachedSkills = _skillRepository.getAllSkills();

    // If showing search suggestions, don't filter skills
    if (_showSearchSuggestions) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Apply search filter
    if (_isSearching && _searchQuery.isNotEmpty) {
      // Add to search history when filtering skills
      if (!_searchHistory.contains(_searchQuery) && _searchQuery.length > 2) {
        setState(() {
          _searchHistory.insert(0, _searchQuery); // Add to beginning
          // Keep only the last 10 searches
          if (_searchHistory.length > 10) {
            _searchHistory.removeLast();
          }
        });
        // Save search history to SharedPreferences
        _saveSearchHistory();
      }
      final lowerQuery = _searchQuery.toLowerCase();

      // For any search query, we'll be very strict - only show exact matches
      // This is to ensure we show "No results found" for unmatched words

      // Check if this is likely a random/unmatched search
      final isRandomText = !_containsCommonWords(_searchQuery);

      // For random text, don't even try to filter - just show no results
      if (isRandomText) {
        debugPrint('Random text detected: $_searchQuery - showing no results');
        setState(() {
          _filteredSkills = [];
          _isLoading = false;
          _showingRelatedResults = false;
        });
        return;
      }

      // Split the query into words for matching
      final queryWords = lowerQuery
          .split(RegExp(r'\s+'))
          .where((word) => word.length > 1) // Only use words with 2+ characters
          .toList();

      // If no valid search words, show empty results
      if (queryWords.isEmpty) {
        setState(() {
          _filteredSkills = [];
          _isLoading = false;
          _showingRelatedResults = false;
        });
        return;
      }

      // VERY Strict search - only show EXACT matches
      var filtered = cachedSkills.where((skill) {
        final skillTitle = skill.title.toLowerCase();
        final skillDesc = skill.description.toLowerCase();
        final skillProvider = skill.provider.toLowerCase();
        final skillCategory = skill.category.toLowerCase();
        final skillLocation = skill.location?.toLowerCase() ?? '';

        // For single word searches, require exact match
        if (queryWords.length == 1) {
          final word = queryWords[0];
          // Only match if the word appears as a complete word, not as part of another word
          final titleMatches = RegExp('\\b$word\\b').hasMatch(skillTitle);
          final descMatches = RegExp('\\b$word\\b').hasMatch(skillDesc);
          final providerMatches = RegExp('\\b$word\\b').hasMatch(skillProvider);
          final categoryMatches = RegExp('\\b$word\\b').hasMatch(skillCategory);
          final locationMatches = skillLocation.isNotEmpty &&
              RegExp('\\b$word\\b').hasMatch(skillLocation);

          return titleMatches ||
              descMatches ||
              providerMatches ||
              categoryMatches ||
              locationMatches;
        } else {
          // For multi-word searches, check if ALL words appear as complete words
          for (final word in queryWords) {
            final titleMatches = RegExp('\\b$word\\b').hasMatch(skillTitle);
            final descMatches = RegExp('\\b$word\\b').hasMatch(skillDesc);
            final providerMatches =
                RegExp('\\b$word\\b').hasMatch(skillProvider);
            final categoryMatches =
                RegExp('\\b$word\\b').hasMatch(skillCategory);
            final locationMatches = skillLocation.isNotEmpty &&
                RegExp('\\b$word\\b').hasMatch(skillLocation);

            // If any word is not found as a complete word in any field, exclude this skill
            if (!titleMatches &&
                !descMatches &&
                !providerMatches &&
                !categoryMatches &&
                !locationMatches) {
              return false;
            }
          }

          // If we get here, all words were found as complete words
          return true;
        }
      }).toList();

      // If we found matches, update UI immediately
      if (filtered.isNotEmpty) {
        // Remove duplicates by ID
        final Map<String, Skill> uniqueSkills = {};
        for (final skill in filtered) {
          uniqueSkills[skill.id] = skill;
        }
        filtered = uniqueSkills.values.toList();

        // Sort by relevance (title matches first, then description, etc.)
        filtered.sort((a, b) {
          // First, check if all query words are in the title
          final aAllWordsInTitle =
              queryWords.every((word) => a.title.toLowerCase().contains(word));
          final bAllWordsInTitle =
              queryWords.every((word) => b.title.toLowerCase().contains(word));

          if (aAllWordsInTitle && !bAllWordsInTitle) return -1;
          if (!aAllWordsInTitle && bAllWordsInTitle) return 1;

          // Then check for exact title match
          final aExactTitle = a.title.toLowerCase() == lowerQuery;
          final bExactTitle = b.title.toLowerCase() == lowerQuery;

          if (aExactTitle && !bExactTitle) return -1;
          if (!aExactTitle && bExactTitle) return 1;

          // If both match or don't match title, sort by creation date
          return b.createdAt.compareTo(a.createdAt);
        });

        setState(() {
          _filteredSkills = filtered;
          _isLoading = false;
          _showSearchSuggestions =
              false; // Hide suggestions when showing results
          _showingRelatedResults = false;
        });
        return;
      }

      // If no exact matches found, try to find related results
      debugPrint('No exact matches found, looking for related results');
      _findRelatedResults();
      return; // _findRelatedResults will update the UI
    }

    // If not searching or query is empty, load all skills
    _loadSkills(forceRefresh: false);

    // Set a timer to hide the loading indicator after a short time
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Flag to track if we're showing related results
  bool _showingRelatedResults = false;

  // Find related results when exact match is not found
  void _findRelatedResults() {
    // For random text, don't even try to find related results
    if (!_containsCommonWords(_searchQuery)) {
      setState(() {
        _filteredSkills = [];
        _isLoading = false;
        _showingRelatedResults = false;
      });
      return;
    }

    // Split search query into words
    final queryWords = _searchQuery
        .toLowerCase()
        .split(' ')
        .where((word) => word.length > 2) // Only use words with 3+ characters
        .toList();

    // If no valid search words, show empty results
    if (queryWords.isEmpty) {
      setState(() {
        _filteredSkills = [];
        _isLoading = false;
        _showingRelatedResults = false;
      });
      return;
    }

    // Get all skills from local cache immediately
    final allSkills = _skillRepository.getAllSkills();

    // Create a map to store skills with their relevance score
    final Map<Skill, int> skillScores = {};

    // Calculate relevance score for each skill
    for (final skill in allSkills) {
      int score = 0;
      final title = skill.title.toLowerCase();
      final description = skill.description.toLowerCase();
      final category = skill.category.toLowerCase();
      final provider = skill.provider.toLowerCase();

      // Check each query word against skill properties
      for (final word in queryWords) {
        // Title matches are most important
        if (title.contains(word)) {
          score += 10;
          // Exact title match gets bonus points
          if (title == word) score += 15;
          // Title starts with the word gets bonus points
          if (title.startsWith(word)) score += 5;
        }

        // Category matches are next most important
        if (category.contains(word)) {
          score += 8;
          // Exact category match gets bonus points
          if (category == word) score += 10;
        }

        // Description matches
        if (description.contains(word)) {
          score += 5;
        }

        // Provider matches
        if (provider.contains(word)) {
          score += 7;
        }
      }

      // Only include skills with a score above a minimum threshold
      // This ensures we only show truly relevant results
      if (score > 5) {
        // Increased from 0 to 5 to be more strict
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

    // Apply category filter if needed
    List<Skill> filteredRelatedSkills = uniqueSortedSkills;
    if (_selectedCategory != 'All') {
      filteredRelatedSkills = uniqueSortedSkills
          .where((skill) => skill.category == _selectedCategory)
          .toList();
    }

    setState(() {
      _filteredSkills = filteredRelatedSkills;
      _isLoading = false;
      _showingRelatedResults = filteredRelatedSkills.isNotEmpty;
    });

    if (filteredRelatedSkills.isEmpty) {
      debugPrint('No related results found for: $_searchQuery');
    } else {
      debugPrint(
          'Found ${filteredRelatedSkills.length} related results for: $_searchQuery');
      // Log the top 3 results with their scores for debugging
      for (int i = 0;
          i < (relatedSkills.length > 3 ? 3 : relatedSkills.length);
          i++) {
        final entry = relatedSkills[i];
        debugPrint('  ${i + 1}. ${entry.key.title} (Score: ${entry.value})');
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
      _showingRelatedResults = false;
      _showSearchSuggestions = false;
      _filteredSkills = []; // Clear filtered skills
    });
    _loadSkills(forceRefresh: false); // Reset to all skills
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

    // Add to search history when user taps a skill
    if (_searchQuery.isNotEmpty &&
        !_searchHistory.contains(_searchQuery) &&
        _searchQuery.length > 2 &&
        !_searchQuery.startsWith('Related to:')) {
      debugPrint('Adding to search history: $_searchQuery');
      setState(() {
        _searchHistory.insert(0, _searchQuery); // Add to beginning
        // Keep only the last 10 searches
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
      // Save search history to SharedPreferences
      _saveSearchHistory();
    }

    // First navigate to the detail page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SkillDetailPage(skill: skill),
      ),
    ).then((_) {
      // When returning from detail page, show related skills
      if (_isSearching) {
        _showRelatedSkills(skill);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _loadSkills(forceRefresh: true),
      child: Scaffold(
        appBar: AppBar(
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
                                  onTap: () {
                                    _searchController.clear();
                                    _clearSearch();
                                  },
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
                      // When search bar is tapped, show search suggestions
                      setState(() {
                        _isSearching = true;
                        _showSearchSuggestions =
                            true; // Always show suggestions when tapped
                        _filteredSkills = []; // Clear any previous results
                      });
                      // Force UI update to show suggestions immediately
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      // Perform search when user presses enter/search
                      if (value.isNotEmpty) {
                        // Add to search history when user submits a search
                        final trimmedValue = value.trim();
                        if (!_searchHistory.contains(trimmedValue) &&
                            trimmedValue.length > 2) {
                          setState(() {
                            _searchHistory.insert(
                                0, trimmedValue); // Add to beginning
                            // Keep only the last 10 searches
                            if (_searchHistory.length > 10) {
                              _searchHistory.removeLast();
                            }
                          });
                          // Save search history to SharedPreferences
                          _saveSearchHistory();
                        }

                        setState(() {
                          _searchQuery = trimmedValue;
                          _isSearching = true;
                          _showSearchSuggestions =
                              false; // Hide suggestions when submitting
                          _showingRelatedResults =
                              false; // Reset related results flag
                        });
                        _filterSkills();

                        // Show a snackbar to indicate search is in progress
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Searching for "$trimmedValue"...'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                )
              : const Text('Skill Hub'),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              tooltip: _isSearching ? 'Cancel Search' : 'Search Skills',
              onPressed: () {
                if (_isSearching) {
                  if (_searchController.text.isNotEmpty) {
                    // Add to search history when user clicks search icon with text
                    final trimmedValue = _searchController.text.trim();
                    if (!_searchHistory.contains(trimmedValue) &&
                        trimmedValue.length > 2) {
                      setState(() {
                        _searchHistory.insert(
                            0, trimmedValue); // Add to beginning
                        // Keep only the last 10 searches
                        if (_searchHistory.length > 10) {
                          _searchHistory.removeLast();
                        }
                      });
                      // Save search history to SharedPreferences
                      _saveSearchHistory();
                    }

                    // Update search query and filter skills
                    setState(() {
                      _searchQuery = trimmedValue;
                      _showSearchSuggestions = false;
                    });

                    // First, check if this is likely a random/unmatched search
                    final isRandomText = !_containsCommonWords(trimmedValue);

                    // For random text, don't even try to filter - just show no results
                    if (isRandomText) {
                      debugPrint(
                          'Random text detected in search icon click: $trimmedValue - showing no results');
                      setState(() {
                        _filteredSkills = [];
                        _isLoading = false;
                        _showingRelatedResults = false;
                      });

                      // Show a snackbar to indicate no results found
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No results found for "$trimmedValue"'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    // Check if the search query matches any skills
                    final lowerQuery = trimmedValue.toLowerCase();
                    final cachedSkills = _skillRepository.getAllSkills();

                    // Split the query into words
                    final queryWords = lowerQuery
                        .split(RegExp(r'\s+'))
                        .where((word) => word.length > 1)
                        .toList();

                    // If no valid search words, show empty results
                    if (queryWords.isEmpty) {
                      setState(() {
                        _filteredSkills = [];
                        _isLoading = false;
                        _showingRelatedResults = false;
                      });
                      return;
                    }

                    // Check if any skill matches ALL query words EXACTLY
                    bool hasMatch = false;
                    for (final skill in cachedSkills) {
                      final skillTitle = skill.title.toLowerCase();
                      final skillDesc = skill.description.toLowerCase();
                      final skillProvider = skill.provider.toLowerCase();
                      final skillCategory = skill.category.toLowerCase();
                      final skillLocation = skill.location?.toLowerCase() ?? '';

                      // For single word searches, require exact match
                      if (queryWords.length == 1) {
                        final word = queryWords[0];
                        // Only match if the word appears as a complete word, not as part of another word
                        final titleMatches =
                            RegExp('\\b$word\\b').hasMatch(skillTitle);
                        final descMatches =
                            RegExp('\\b$word\\b').hasMatch(skillDesc);
                        final providerMatches =
                            RegExp('\\b$word\\b').hasMatch(skillProvider);
                        final categoryMatches =
                            RegExp('\\b$word\\b').hasMatch(skillCategory);
                        final locationMatches = skillLocation.isNotEmpty &&
                            RegExp('\\b$word\\b').hasMatch(skillLocation);

                        if (titleMatches ||
                            descMatches ||
                            providerMatches ||
                            categoryMatches ||
                            locationMatches) {
                          hasMatch = true;
                          break;
                        }
                      } else {
                        // For multi-word searches, check if ALL words appear as complete words
                        bool allWordsMatch = true;
                        for (final word in queryWords) {
                          final titleMatches =
                              RegExp('\\b$word\\b').hasMatch(skillTitle);
                          final descMatches =
                              RegExp('\\b$word\\b').hasMatch(skillDesc);
                          final providerMatches =
                              RegExp('\\b$word\\b').hasMatch(skillProvider);
                          final categoryMatches =
                              RegExp('\\b$word\\b').hasMatch(skillCategory);
                          final locationMatches = skillLocation.isNotEmpty &&
                              RegExp('\\b$word\\b').hasMatch(skillLocation);

                          // If any word is not found as a complete word in any field, exclude this skill
                          if (!titleMatches &&
                              !descMatches &&
                              !providerMatches &&
                              !categoryMatches &&
                              !locationMatches) {
                            allWordsMatch = false;
                            break;
                          }
                        }

                        if (allWordsMatch) {
                          hasMatch = true;
                          break;
                        }
                      }
                    }

                    if (hasMatch) {
                      _filterSkills(); // Only filter if there are matches
                    } else {
                      // No matches, show empty state
                      setState(() {
                        _filteredSkills = [];
                        _isLoading = false;
                        _showingRelatedResults = false;
                      });

                      // Show a snackbar to indicate no results found
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No results found for "$trimmedValue"'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    // If search is empty, clear the search
                    _clearSearch();
                  }
                } else {
                  // If not searching, start searching and show suggestions
                  setState(() {
                    _isSearching = true;
                    _showSearchSuggestions =
                        true; // Show suggestions immediately
                    _filteredSkills = []; // Clear any previous results
                  });
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Connectivity status indicator
                const ConnectivityStatusIndicator(),

                // Only show category filter when not searching
                if (!_isSearching) _buildCategoryFilter(),
                const SizedBox(height: 8),
                Expanded(
                  child: _isSearching &&
                          _searchController.text.isNotEmpty &&
                          _filteredSkills.isNotEmpty
                      ? // Show search results when we have matches and text in search bar
                      SearchResultsList(
                          skills: _filteredSkills,
                          searchQuery: _searchQuery,
                          onSkillTap: _onSkillTap,
                          isLoading: _isLoading,
                          showRelatedHeader: _showingRelatedResults,
                        )
                      : _isSearching && _showSearchSuggestions
                          ? // Show search suggestions when search bar is tapped
                          SearchSuggestions(
                              suggestions: _getSearchSuggestions(),
                              onSuggestionTap: (suggestion) {
                                _searchController.text = suggestion;

                                // Add to search history when user taps a suggestion
                                if (!_searchHistory.contains(suggestion) &&
                                    suggestion.length > 2 &&
                                    !suggestion.startsWith('Category:')) {
                                  setState(() {
                                    _searchHistory.insert(
                                        0, suggestion); // Add to beginning
                                    // Keep only the last 10 searches
                                    if (_searchHistory.length > 10) {
                                      _searchHistory.removeLast();
                                    }
                                  });
                                  // Save search history to SharedPreferences
                                  _saveSearchHistory();
                                }

                                // Immediately set the search query and filter skills
                                setState(() {
                                  _searchQuery = suggestion;
                                  _isSearching = true;
                                  _showSearchSuggestions =
                                      false; // Hide suggestions after selection
                                  _isLoading =
                                      true; // Show loading indicator briefly
                                });

                                // Get all skills from local cache
                                final cachedSkills =
                                    _skillRepository.getAllSkills();
                                final lowerQuery = suggestion.toLowerCase();

                                // Check if this is likely a random/unmatched search
                                final isRandomText =
                                    !_containsCommonWords(suggestion);

                                // For random text, don't even try to filter - just show no results
                                if (isRandomText) {
                                  debugPrint(
                                      'Random text detected in suggestion: $suggestion - showing no results');
                                  setState(() {
                                    _filteredSkills = [];
                                    _isLoading = false;
                                    _showingRelatedResults = false;
                                  });
                                  return;
                                }

                                // Split the query into words
                                final queryWords = lowerQuery
                                    .split(RegExp(r'\s+'))
                                    .where((word) => word.length > 1)
                                    .toList();

                                // If no valid search words, show empty results
                                if (queryWords.isEmpty) {
                                  setState(() {
                                    _filteredSkills = [];
                                    _isLoading = false;
                                    _showingRelatedResults = false;
                                  });
                                  return;
                                }

                                // VERY Strict search - only show EXACT matches
                                final filtered = cachedSkills.where((skill) {
                                  final skillTitle = skill.title.toLowerCase();
                                  final skillDesc =
                                      skill.description.toLowerCase();
                                  final skillProvider =
                                      skill.provider.toLowerCase();
                                  final skillCategory =
                                      skill.category.toLowerCase();
                                  final skillLocation =
                                      skill.location?.toLowerCase() ?? '';

                                  // For single word searches, require exact match
                                  if (queryWords.length == 1) {
                                    final word = queryWords[0];
                                    // Only match if the word appears as a complete word, not as part of another word
                                    final titleMatches = RegExp('\\b$word\\b')
                                        .hasMatch(skillTitle);
                                    final descMatches = RegExp('\\b$word\\b')
                                        .hasMatch(skillDesc);
                                    final providerMatches =
                                        RegExp('\\b$word\\b')
                                            .hasMatch(skillProvider);
                                    final categoryMatches =
                                        RegExp('\\b$word\\b')
                                            .hasMatch(skillCategory);
                                    final locationMatches =
                                        skillLocation.isNotEmpty &&
                                            RegExp('\\b$word\\b')
                                                .hasMatch(skillLocation);

                                    return titleMatches ||
                                        descMatches ||
                                        providerMatches ||
                                        categoryMatches ||
                                        locationMatches;
                                  } else {
                                    // For multi-word searches, check if ALL words appear as complete words
                                    for (final word in queryWords) {
                                      final titleMatches = RegExp('\\b$word\\b')
                                          .hasMatch(skillTitle);
                                      final descMatches = RegExp('\\b$word\\b')
                                          .hasMatch(skillDesc);
                                      final providerMatches =
                                          RegExp('\\b$word\\b')
                                              .hasMatch(skillProvider);
                                      final categoryMatches =
                                          RegExp('\\b$word\\b')
                                              .hasMatch(skillCategory);
                                      final locationMatches =
                                          skillLocation.isNotEmpty &&
                                              RegExp('\\b$word\\b')
                                                  .hasMatch(skillLocation);

                                      // If any word is not found as a complete word in any field, exclude this skill
                                      if (!titleMatches &&
                                          !descMatches &&
                                          !providerMatches &&
                                          !categoryMatches &&
                                          !locationMatches) {
                                        return false;
                                      }
                                    }

                                    // If we get here, all words were found as complete words
                                    return true;
                                  }
                                }).toList();

                                // Split the query into individual characters for scoring
                                final queryChars = lowerQuery.split('');

                                // Sort results by relevance
                                filtered.sort((a, b) {
                                  // First, check for exact matches in title
                                  final aTitle = a.title
                                      .toLowerCase()
                                      .contains(lowerQuery);
                                  final bTitle = b.title
                                      .toLowerCase()
                                      .contains(lowerQuery);
                                  if (aTitle && !bTitle) {
                                    return -1;
                                  }
                                  if (!aTitle && bTitle) {
                                    return 1;
                                  }

                                  // Then check for exact matches in category
                                  final aCategory = a.category
                                      .toLowerCase()
                                      .contains(lowerQuery);
                                  final bCategory = b.category
                                      .toLowerCase()
                                      .contains(lowerQuery);
                                  if (aCategory && !bCategory) {
                                    return -1;
                                  }
                                  if (!aCategory && bCategory) {
                                    return 1;
                                  }

                                  // If query has multiple characters, calculate match score for each skill
                                  if (queryChars.length > 1) {
                                    // Calculate match score for skill A
                                    int aScore = 0;
                                    final aLowerTitle = a.title.toLowerCase();
                                    final aLowerDesc =
                                        a.description.toLowerCase();
                                    final aLowerProvider =
                                        a.provider.toLowerCase();
                                    final aLowerCategory =
                                        a.category.toLowerCase();
                                    final aLowerLocation =
                                        a.location?.toLowerCase() ?? '';

                                    // Calculate match score for skill B
                                    int bScore = 0;
                                    final bLowerTitle = b.title.toLowerCase();
                                    final bLowerDesc =
                                        b.description.toLowerCase();
                                    final bLowerProvider =
                                        b.provider.toLowerCase();
                                    final bLowerCategory =
                                        b.category.toLowerCase();
                                    final bLowerLocation =
                                        b.location?.toLowerCase() ?? '';

                                    // Check each character
                                    for (final char in queryChars) {
                                      // Add to score A
                                      if (aLowerTitle.contains(char)) {
                                        aScore +=
                                            3; // Title matches are most important
                                      }
                                      if (aLowerCategory.contains(char)) {
                                        aScore +=
                                            2; // Category matches are next
                                      }
                                      if (aLowerDesc.contains(char)) {
                                        aScore += 1;
                                      }
                                      if (aLowerProvider.contains(char)) {
                                        aScore += 1;
                                      }
                                      if (aLowerLocation.contains(char)) {
                                        aScore += 1;
                                      }

                                      // Add to score B
                                      if (bLowerTitle.contains(char)) {
                                        bScore += 3;
                                      }
                                      if (bLowerCategory.contains(char)) {
                                        bScore += 2;
                                      }
                                      if (bLowerDesc.contains(char)) {
                                        bScore += 1;
                                      }
                                      if (bLowerProvider.contains(char)) {
                                        bScore += 1;
                                      }
                                      if (bLowerLocation.contains(char)) {
                                        bScore += 1;
                                      }
                                    }

                                    // Sort by score (higher score first)
                                    if (aScore != bScore) {
                                      return bScore -
                                          aScore; // Higher score first
                                    }
                                  }

                                  // If scores are equal or we have a single character query, sort by creation date
                                  return b.createdAt.compareTo(a.createdAt);
                                });

                                // Remove duplicates by ID
                                final Map<String, Skill> uniqueSkills = {};
                                for (final skill in filtered) {
                                  uniqueSkills[skill.id] = skill;
                                }
                                final uniqueFiltered =
                                    uniqueSkills.values.toList();

                                // Update UI with filtered skills
                                setState(() {
                                  _filteredSkills = uniqueFiltered;
                                  _isLoading = false;
                                  _showingRelatedResults = false;
                                });

                                // Show a snackbar to indicate search is in progress
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Searching for "$suggestion"...'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              onClearHistory: _clearSearchHistory,
                            )
                          : _isSearching && _filteredSkills.isNotEmpty
                              ? // Show search results when we have matches
                              SearchResultsList(
                                  skills: _filteredSkills,
                                  searchQuery: _searchQuery,
                                  onSkillTap: _onSkillTap,
                                  isLoading: _isLoading,
                                  showRelatedHeader: _showingRelatedResults,
                                )
                              : _isSearching &&
                                      _searchController.text.isNotEmpty &&
                                      _filteredSkills.isEmpty &&
                                      !_showingRelatedResults
                                  ? // Show search suggestions when searching with no results
                                  SearchSuggestions(
                                      suggestions: _getSearchSuggestions(),
                                      onSuggestionTap: (suggestion) {
                                        _searchController.text = suggestion;

                                        // Add to search history when user taps a suggestion
                                        if (!_searchHistory
                                                .contains(suggestion) &&
                                            suggestion.length > 2 &&
                                            !suggestion
                                                .startsWith('Category:')) {
                                          setState(() {
                                            _searchHistory.insert(0,
                                                suggestion); // Add to beginning
                                            // Keep only the last 10 searches
                                            if (_searchHistory.length > 10) {
                                              _searchHistory.removeLast();
                                            }
                                          });
                                          // Save search history to SharedPreferences
                                          _saveSearchHistory();
                                        }

                                        // Immediately set the search query and filter skills
                                        setState(() {
                                          _searchQuery = suggestion;
                                          _isSearching = true;
                                          _showSearchSuggestions =
                                              false; // Hide suggestions after selection
                                          _isLoading =
                                              true; // Show loading indicator briefly
                                        });

                                        // Get all skills from local cache
                                        final cachedSkills =
                                            _skillRepository.getAllSkills();
                                        final lowerQuery =
                                            suggestion.toLowerCase();

                                        // Split the query into individual characters
                                        final queryChars = lowerQuery.split('');

                                        // Filter skills immediately
                                        final filtered =
                                            cachedSkills.where((skill) {
                                          // Check if the skill contains the full query
                                          final titleContains = skill.title
                                              .toLowerCase()
                                              .contains(lowerQuery);
                                          final descContains = skill.description
                                              .toLowerCase()
                                              .contains(lowerQuery);
                                          final providerContains = skill
                                              .provider
                                              .toLowerCase()
                                              .contains(lowerQuery);
                                          final categoryContains = skill
                                              .category
                                              .toLowerCase()
                                              .contains(lowerQuery);
                                          final locationContains =
                                              skill.location != null &&
                                                  skill.location!
                                                      .toLowerCase()
                                                      .contains(lowerQuery);

                                          // If any field contains the full query, include it
                                          if (titleContains ||
                                              descContains ||
                                              providerContains ||
                                              categoryContains ||
                                              locationContains) {
                                            return true;
                                          }

                                          // If the query is more than one character, check if it contains individual characters
                                          if (queryChars.length > 1) {
                                            // Count how many characters from the query are found in each field
                                            int matchCount = 0;
                                            final lowerTitle =
                                                skill.title.toLowerCase();
                                            final lowerDesc =
                                                skill.description.toLowerCase();
                                            final lowerProvider =
                                                skill.provider.toLowerCase();
                                            final lowerCategory =
                                                skill.category.toLowerCase();
                                            final lowerLocation =
                                                skill.location?.toLowerCase() ??
                                                    '';

                                            // Check each character
                                            for (final char in queryChars) {
                                              if (lowerTitle.contains(char) ||
                                                  lowerDesc.contains(char) ||
                                                  lowerProvider
                                                      .contains(char) ||
                                                  lowerCategory
                                                      .contains(char) ||
                                                  lowerLocation
                                                      .contains(char)) {
                                                matchCount++;
                                              }
                                            }

                                            // If at least half of the characters match, include it
                                            return matchCount >=
                                                (queryChars.length / 2).ceil();
                                          }

                                          // For single character queries, we already checked above
                                          return false;
                                        }).toList();

                                        // Sort results by relevance
                                        filtered.sort((a, b) {
                                          // Title matches first
                                          final aTitle = a.title
                                              .toLowerCase()
                                              .contains(lowerQuery);
                                          final bTitle = b.title
                                              .toLowerCase()
                                              .contains(lowerQuery);
                                          if (aTitle && !bTitle) {
                                            return -1;
                                          }
                                          if (!aTitle && bTitle) {
                                            return 1;
                                          }

                                          // Then category matches
                                          final aCategory = a.category
                                              .toLowerCase()
                                              .contains(lowerQuery);
                                          final bCategory = b.category
                                              .toLowerCase()
                                              .contains(lowerQuery);
                                          if (aCategory && !bCategory) {
                                            return -1;
                                          }
                                          if (!aCategory && bCategory) {
                                            return 1;
                                          }

                                          // Then by creation date
                                          return b.createdAt
                                              .compareTo(a.createdAt);
                                        });

                                        // Update UI with filtered skills
                                        setState(() {
                                          _filteredSkills = filtered;
                                          _isLoading = false;
                                          _showingRelatedResults = false;
                                        });

                                        // Show a snackbar to indicate search is in progress
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Searching for "$suggestion"...'),
                                            duration:
                                                const Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                      onClearHistory: _clearSearchHistory,
                                    )
                                  : _isSearching &&
                                          _searchController.text.isNotEmpty &&
                                          _filteredSkills.isEmpty &&
                                          !_showingRelatedResults
                                      ? // Show search suggestions when searching with no results
                                      SearchSuggestions(
                                          suggestions: _getSearchSuggestions(),
                                          onSuggestionTap: (suggestion) {
                                            _searchController.text = suggestion;

                                            // Add to search history when user taps a suggestion
                                            if (!_searchHistory
                                                    .contains(suggestion) &&
                                                suggestion.length > 2 &&
                                                !suggestion
                                                    .startsWith('Category:')) {
                                              setState(() {
                                                _searchHistory.insert(0,
                                                    suggestion); // Add to beginning
                                                // Keep only the last 10 searches
                                                if (_searchHistory.length >
                                                    10) {
                                                  _searchHistory.removeLast();
                                                }
                                              });
                                              // Save search history to SharedPreferences
                                              _saveSearchHistory();
                                            }

                                            // Immediately set the search query and filter skills
                                            setState(() {
                                              _searchQuery = suggestion;
                                              _isSearching = true;
                                              _showSearchSuggestions =
                                                  false; // Hide suggestions after selection
                                              _isLoading =
                                                  true; // Show loading indicator briefly
                                            });

                                            // Get all skills from local cache
                                            final cachedSkills =
                                                _skillRepository.getAllSkills();
                                            final lowerQuery =
                                                suggestion.toLowerCase();

                                            // Filter skills immediately
                                            final filtered =
                                                cachedSkills.where((skill) {
                                              return skill.title
                                                      .toLowerCase()
                                                      .contains(lowerQuery) ||
                                                  skill.description
                                                      .toLowerCase()
                                                      .contains(lowerQuery) ||
                                                  skill.provider
                                                      .toLowerCase()
                                                      .contains(lowerQuery) ||
                                                  skill.category
                                                      .toLowerCase()
                                                      .contains(lowerQuery) ||
                                                  (skill.location != null &&
                                                      skill.location!
                                                          .toLowerCase()
                                                          .contains(
                                                              lowerQuery));
                                            }).toList();

                                            // Update UI with filtered skills
                                            setState(() {
                                              _filteredSkills = filtered;
                                              _isLoading = false;
                                              _showingRelatedResults = false;
                                            });

                                            // Show a snackbar to indicate search is in progress
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Searching for "$suggestion"...'),
                                                duration:
                                                    const Duration(seconds: 1),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          onClearHistory: _clearSearchHistory,
                                        )
                                      : _filteredSkills.isEmpty
                                          ? _buildEmptyState()
                                          : SkillList(
                                              skills: _filteredSkills,
                                              onSkillTap: _onSkillTap,
                                            ),
                ),
              ],
            ),

            // Loading indicator overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
        // Removed FloatingActionButton since it's now in the MainContainer
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
