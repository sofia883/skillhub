import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/skill_card.dart';
import '../widgets/category_chip.dart';
import '../../domain/entities/skill.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Programming',
    'Design',
    'Marketing',
    'Writing',
    'Music',
    'Fitness',
    'Cooking',
    'Languages',
  ];

  // Mock data - this will later come from a repository
  final List<Skill> _skills = [
    Skill(
      id: '1',
      title: 'Flutter App Development',
      description:
          'Expert in building cross-platform mobile applications using Flutter',
      category: 'Programming',
      price: 50,
      rating: 4.8,
      provider: 'John Doe',
      imageUrl: 'https://picsum.photos/seed/flutter/300/200',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Skill(
      id: '2',
      title: 'UI/UX Design',
      description: 'Professional UI/UX design for web and mobile applications',
      category: 'Design',
      price: 45,
      rating: 4.7,
      provider: 'Jane Smith',
      imageUrl: 'https://picsum.photos/seed/design/300/200',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    Skill(
      id: '3',
      title: 'Content Writing',
      description: 'SEO-optimized content writing for blogs and websites',
      category: 'Writing',
      price: 30,
      rating: 4.5,
      provider: 'Alice Johnson',
      imageUrl: 'https://picsum.photos/seed/writing/300/200',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Skill(
      id: '4',
      title: 'Social Media Marketing',
      description: 'Strategic marketing for social media platforms',
      category: 'Marketing',
      price: 40,
      rating: 4.6,
      provider: 'Bob Brown',
      imageUrl: 'https://picsum.photos/seed/marketing/300/200',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    Skill(
      id: '5',
      title: 'Piano Lessons',
      description:
          'Private piano lessons for beginners and intermediate players',
      category: 'Music',
      price: 35,
      rating: 4.9,
      provider: 'Charlie Davis',
      imageUrl: 'https://picsum.photos/seed/piano/300/200',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  List<Skill> get filteredSkills {
    if (_selectedCategory == 'All') {
      return _skills;
    } else {
      return _skills
          .where((skill) => skill.category == _selectedCategory)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _buildSkillsList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Add Skill',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
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
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkillsList() {
    return filteredSkills.isEmpty
        ? const Center(
            child: Text(
              'No skills found in this category',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredSkills.length,
            itemBuilder: (context, index) {
              final skill = filteredSkills[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SkillCard(
                  skill: skill,
                  onTap: () {
                    // TODO: Navigate to skill detail screen
                  },
                ),
              );
            },
          );
  }
}
