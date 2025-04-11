import 'package:flutter/material.dart';
import 'package:skill_hub/features/home/presentation/pages/home_screen.dart';
import 'package:skill_hub/features/profile/presentation/pages/profile_page.dart';
import 'package:skill_hub/features/skills/presentation/pages/add_skill_page.dart';
import 'package:skill_hub/features/settings/presentation/pages/settings_page.dart';
import 'package:skill_hub/features/saved/presentation/pages/saved_skills_page.dart';
import 'package:skill_hub/features/chat/presentation/pages/chat_list_screen.dart';
import 'package:skill_hub/core/theme/app_theme.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  // List of screens to navigate between
  final List<Widget> _screens = [
    const HomeScreen(),
    const ProfilePage(),
    const ChatListScreen(),
    const SavedSkillsPage(),
    const SettingsPage(),
  ];

  // Add a key to access the scaffold for showing snackbars
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigate to Add Skill page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddSkillPage()),
            ).then((result) {
              // If result is true, a skill was added successfully
              if (result == true && _currentIndex == 0) {
                // Create a new HomeScreen instance to force a complete refresh
                setState(() {
                  _screens[0] = HomeScreen(key: UniqueKey());
                });

                // Show a snackbar to indicate the skill was added
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Skill added successfully! Refreshing...'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            });
          },
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home, 'Home'),
              _buildNavItem(1, Icons.person, 'Profile'),
              // Empty space for FAB
              const SizedBox(width: 40),
              _buildNavItem(2, Icons.chat, 'Chats'),
              _buildNavItem(3, Icons.bookmark, 'Saved'),
              _buildNavItem(4, Icons.settings, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    // Adjust index for items after the FAB
    final adjustedIndex = index >= 2 ? index - 1 : index;
    final isSelected = adjustedIndex == _currentIndex;

    return InkWell(
      onTap: () {
        // All navigation items are now functional
        setState(() {
          _currentIndex = adjustedIndex;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
