import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skill_hub/features/home/presentation/pages/home_screen.dart';
import 'package:skill_hub/features/profile/presentation/pages/profile_page.dart';
import 'package:skill_hub/features/posts/presentation/pages/add_post_page.dart';
import 'package:skill_hub/features/jobs/presentation/pages/jobs_page.dart';

class MainContainer extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const MainContainer({
    super.key,
    this.arguments,
  });

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  final List<int> _navigationStack = [0];
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    if (widget.arguments != null) {
      final initialIndex = widget.arguments!['initialIndex'] as int?;
      final clearStack = widget.arguments!['clearStack'] as bool? ?? false;

      if (initialIndex != null) {
        setState(() {
          _currentIndex = initialIndex;
          if (clearStack) {
            _navigationStack.clear();
            _navigationStack.add(0);
            _navigationStack.add(initialIndex);
          } else {
            _navigationStack.add(initialIndex);
          }
        });
      }
    }
  }

  void _initializeScreens() {
    _screens = [
      const HomeScreen(key: ValueKey('home')),
      const AddPostPage(key: ValueKey('post')),
      const JobsPage(key: ValueKey('jobs')),
      const ProfilePage(key: ValueKey('profile')),
    ];
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex == 0) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                SystemNavigator.pop();
              },
              child: const Text('Exit'),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }

    if (_navigationStack.length > 1) {
      setState(() {
        _navigationStack.removeLast();
        _currentIndex = _navigationStack.last;
      });
      return false;
    }

    setState(() {
      _currentIndex = 0;
      _navigationStack.clear();
      _navigationStack.add(0);
    });
    return false;
  }

  void _updateIndex(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
        _navigationStack.add(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    theme: theme,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.add_circle_outline,
                    activeIcon: Icons.add_circle,
                    label: 'Post',
                    theme: theme,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.work_outline_rounded,
                    activeIcon: Icons.work_rounded,
                    label: 'Jobs',
                    theme: theme,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required ThemeData theme,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _updateIndex(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? theme.colorScheme.primary : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? theme.colorScheme.primary : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
