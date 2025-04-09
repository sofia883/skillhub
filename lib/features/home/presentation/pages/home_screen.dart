import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/skill_card.dart';
import '../widgets/category_chip.dart';
import '../../domain/entities/skill.dart';
import '../../data/repositories/skill_repository.dart';
import '../../../../features/search/presentation/pages/search_page.dart';
import '../../../../features/skills/presentation/pages/add_skill_page.dart';
import '../../../../features/profile/presentation/pages/profile_page.dart';
import '../../../../features/home/presentation/widgets/skill_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
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
    'Languages',
    'Other',
  ];

  // Repository for skills
  final _skillRepository = SkillRepository();

  // Skills list
  List<Skill> _allSkills = [];
  List<Skill> _filteredSkills = [];

  @override
  void initState() {
    super.initState();
    _loadSkills(forceRefresh: true);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force refresh when returning to this screen
    _loadSkills(forceRefresh: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSkills({bool forceRefresh = false}) async {
    if (_isLoading) return; // Prevent multiple concurrent loads

    setState(() {
      _isLoading = true;
    });

    try {
      // Force refresh from Firestore and local cache
      final skills =
          await _skillRepository.getSkills(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _allSkills = skills;
          _isLoading = false;
        });
        _filterSkills();
      }
    } catch (e) {
      print('Error loading skills: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text.trim();
          _isSearching = _searchQuery.isNotEmpty;
        });
        _filterSkills();
      }
    });
  }

  void _filterSkills() {
    setState(() {
      _isLoading = true;
    });

    if (_isSearching) {
      // Use searchSkills method for searching
      _skillRepository
          .searchSkills(_searchQuery, _selectedCategory)
          .then((results) {
        setState(() {
          _filteredSkills = results;
          _isLoading = false;
        });
      }).catchError((error) {
        print('Error searching skills: $error');
        setState(() {
          _filteredSkills = [];
          _isLoading = false;
        });
      });
    } else {
      // For category filter only, still use the repository
      _skillRepository.searchSkills('', _selectedCategory).then((results) {
        setState(() {
          _filteredSkills = results;
          _isLoading = false;
        });
      }).catchError((error) {
        print('Error filtering skills: $error');
        setState(() {
          _filteredSkills = [];
          _isLoading = false;
        });
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
    _filterSkills();
  }

  void _navigateToPage(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        // Toggle search instead of navigating to separate page
        setState(() {
          _isSearching = true;
        });
        break;
      case 2:
        // Navigate to add skill
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddSkillPage()),
        ).then((_) {
          // Refresh skills when returning from add skill page
          _loadSkills();
        });
        break;
      case 3:
        // Navigate to saved
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved skills coming soon!')));
        break;
      case 4:
        // Navigate to profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        ).then((_) {
          // Refresh skills when returning from profile page
          _loadSkills();
        });
        break;
    }

    // Reset back to home tab after navigation
    if (index != 0 && index != 1) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    }
  }

  // Handle skill tap
  void _onSkillTap(Skill skill) {
    // Show a snackbar for now (would navigate to details page in a real app)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing ${skill.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _loadSkills(forceRefresh: true),
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search skills...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  autofocus: true,
                )
              : const Text('Skill Hub'),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _filterSkills();
                  }
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildCategoryFilter(),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredSkills.isEmpty
                      ? _buildEmptyState()
                      : SkillGrid(
                          skills: _filteredSkills,
                          onSkillTap: _onSkillTap,
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddSkillPage(),
              ),
            ).then((_) => _loadSkills(forceRefresh: true));
          },
          child: const Icon(Icons.add),
          tooltip: 'Add Skill',
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
                setState(() {
                  _selectedCategory = category;
                });
                _filterSkills();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Working in Offline Mode',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Your skills are being saved locally. Add a new skill to see it here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
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
