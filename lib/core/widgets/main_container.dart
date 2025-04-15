import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:skill_hub/features/home/presentation/pages/home_screen.dart';
import 'package:skill_hub/features/profile/presentation/pages/profile_page.dart';
import 'package:skill_hub/features/skills/presentation/pages/add_skill_page.dart';
import 'package:skill_hub/features/settings/presentation/pages/settings_page.dart';
import 'package:skill_hub/core/theme/app_theme.dart';

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
            // If coming from skill addition, set home as the only previous screen
            _navigationStack.clear();
            _navigationStack.add(0); // Home
            _navigationStack.add(initialIndex);
          } else {
            _navigationStack.clear();
            _navigationStack.add(initialIndex);
          }
        });
      }
    }
  }

  void _initializeScreens() {
    _screens = [
      const HomeScreen(key: ValueKey('home')),
      ProfilePage(
        key: const ValueKey('profile'),
        initialTab: 1, // Always show skills tab when coming from add skill
        newSkillId: widget.arguments?['newSkillId'] as String?,
        showLoadingFor: widget.arguments?['showLoadingFor'] as int?,
      ),
      const AddSkillPage(key: ValueKey('addSkill')),
      const SettingsPage(key: ValueKey('settings')),
    ];
  }

  void _updateIndex(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
        // Always add new index to navigation stack
        _navigationStack.add(index);
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_navigationStack.length > 1) {
      _navigationStack.removeLast();
      setState(() {
        _currentIndex = _navigationStack.last;
      });
      return false;
    }

    // If we're on the home screen (first screen), show exit dialog
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
                SystemNavigator.pop(); // This will completely close the app
              },
              child: const Text('Exit'),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: CurvedNavigationBar(
          backgroundColor: Colors.transparent,
          color: AppTheme.primaryColor,
          buttonBackgroundColor: AppTheme.primaryColor,
          height: 60,
          animationDuration: const Duration(milliseconds: 300),
          animationCurve: Curves.easeInOut,
          index: _currentIndex,
          items: const [
            Icon(Icons.home, color: Colors.white),
            Icon(Icons.person, color: Colors.white),
            Icon(Icons.add, color: Colors.white),
            Icon(Icons.settings, color: Colors.white),
          ],
          onTap: _updateIndex,
        ),
      ),
    );
  }
}
