import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:skill_hub/features/home/presentation/pages/home_screen.dart';
import 'package:skill_hub/features/profile/presentation/pages/profile_page.dart';
import 'package:skill_hub/features/skills/presentation/pages/add_skill_page.dart';
import 'package:skill_hub/features/settings/presentation/pages/settings_page.dart';
import 'package:skill_hub/core/theme/app_theme.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  List<int> _navigationStack = [0]; // Track navigation history, start with home

  // List of screens to navigate between
  final List<Widget> _screens = [
    const HomeScreen(),
    const ProfilePage(),
    const AddSkillPage(),
    const SettingsPage(),
  ];

  // Add a key to access the scaffold for showing snackbars
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  void _updateIndex(int index) {
    if (index != _currentIndex) {
      setState(() {
        _navigationStack.add(_currentIndex); // Add current index to history
        _currentIndex = index;
      });
    } else {
      // If tapping on Add Skills tab and already on that tab, refresh it
      if (index == 2) {
        setState(() {
          _screens[2] = AddSkillPage(key: UniqueKey());
        });
      }
      // If tapping on Home tab and already on that tab, refresh it
      else if (index == 0) {
        setState(() {
          _screens[0] = HomeScreen(key: UniqueKey());
        });
      }
    }
  }

  bool _handleBackButton() {
    if (_navigationStack.isEmpty) {
      return true; // Allow app to close if navigation stack is empty
    }

    // Pop the last screen from navigation stack
    setState(() {
      _currentIndex = _navigationStack.removeLast();
    });
    return false; // Don't close the app
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return _handleBackButton();
      },
      child: ScaffoldMessenger(
        key: _scaffoldKey,
        child: Scaffold(
          body: _screens[_currentIndex],
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
      ),
    );
  }
}
