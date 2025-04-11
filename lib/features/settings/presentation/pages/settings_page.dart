import 'package:flutter/material.dart';
import 'package:skill_hub/core/theme/app_theme.dart';
import 'package:skill_hub/core/widgets/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_hub/features/auth/presentation/pages/login_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  
  final List<String> _languages = ['English', 'Hindi', 'Spanish', 'French', 'German'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Account'),
            _buildSettingItem(
              Icons.person,
              'Edit Profile',
              'Update your personal information',
              () => _showComingSoonSnackBar('Profile editing'),
            ),
            _buildSettingItem(
              Icons.security,
              'Security',
              'Manage your account security',
              () => _showComingSoonSnackBar('Security settings'),
            ),
            _buildSettingItem(
              Icons.payment,
              'Payment Methods',
              'Manage your payment options',
              () => _showComingSoonSnackBar('Payment methods'),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Preferences'),
            
            // Notifications toggle
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Receive push notifications'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _showSettingChangedSnackBar('Notifications ${value ? 'enabled' : 'disabled'}');
              },
              secondary: const Icon(Icons.notifications),
            ),
            
            // Dark mode toggle
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Use dark theme'),
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
                _showSettingChangedSnackBar('Dark mode ${value ? 'enabled' : 'disabled'}');
                _showComingSoonSnackBar('Theme changing');
              },
              secondary: const Icon(Icons.dark_mode),
            ),
            
            // Language dropdown
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.language, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Language',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButton<String>(
                          value: _selectedLanguage,
                          isExpanded: true,
                          underline: Container(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedLanguage = newValue;
                              });
                              _showSettingChangedSnackBar('Language changed to $newValue');
                              _showComingSoonSnackBar('Language changing');
                            }
                          },
                          items: _languages.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Support'),
            _buildSettingItem(
              Icons.help,
              'Help Center',
              'Get help with using the app',
              () => _showComingSoonSnackBar('Help center'),
            ),
            _buildSettingItem(
              Icons.feedback,
              'Send Feedback',
              'Help us improve Skill Hub',
              () => _showComingSoonSnackBar('Feedback form'),
            ),
            _buildSettingItem(
              Icons.policy,
              'Terms & Policies',
              'View our terms and policies',
              () => _showComingSoonSnackBar('Terms and policies'),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('About'),
            _buildSettingItem(
              Icons.info,
              'About Skill Hub',
              'Learn more about our app',
              () => _showComingSoonSnackBar('About page'),
            ),
            _buildSettingItem(
              Icons.update,
              'Check for Updates',
              'Current version: 1.0.0',
              () => _showComingSoonSnackBar('Update checking'),
            ),
            
            const SizedBox(height: 32),
            CustomButton(
              text: 'Sign Out',
              onPressed: _signOut,
              isOutlined: true,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }
  
  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
  
  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showSettingChangedSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }
}
