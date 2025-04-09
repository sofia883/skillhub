import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../features/auth/data/repositories/user_repository.dart';
import '../../../../features/auth/presentation/pages/login_screen.dart';
import '../../../../features/home/data/repositories/skill_repository.dart';
import '../../../../features/home/domain/entities/skill.dart';
import '../../../../features/home/presentation/widgets/skill_card.dart';
import '../../../../features/skills/presentation/pages/add_skill_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _userRepository = UserRepository();
  final _skillRepository = SkillRepository();
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  bool _isLoading = false;

  // User skills
  List<Skill> _userSkills = [];

  // User data
  String _userName = 'User';
  String _userEmail = '';
  String _userBio = 'No bio available';
  String _userLocation = 'Not specified';
  String _userPhone = 'Not provided';
  String _userProfilePic = 'https://via.placeholder.com/150';
  double _userRating = 0.0;
  int _totalJobsDone = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _loadUserSkills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = _userRepository.getCurrentUser();

      if (user != null) {
        // Basic info from Auth
        setState(() {
          _userEmail = user.email ?? 'No email';

          // Extract name from email as fallback
          if (user.displayName != null && user.displayName!.isNotEmpty) {
            _userName = user.displayName!;
          } else if (user.email != null) {
            _userName = user.email!
                .split('@')[0]
                .split('.')
                .map((s) => s.isNotEmpty
                    ? '${s[0].toUpperCase()}${s.substring(1)}'
                    : '')
                .join(' ');
          }

          // Use photo URL if available
          if (user.photoURL != null && user.photoURL!.isNotEmpty) {
            _userProfilePic = user.photoURL!;
          }
        });

        // Try to get additional data from Firestore
        try {
          final userDoc =
              await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null) {
              setState(() {
                _userBio = userData['bio'] ?? _userBio;
                _userLocation = userData['location'] ?? _userLocation;
                _userPhone = userData['phone'] ?? _userPhone;
                _userRating = (userData['rating'] ?? 0).toDouble();
                _totalJobsDone = userData['jobsDone'] ?? 0;
              });
            }
          }
        } catch (e) {
          print('Error fetching additional user data: $e');
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserSkills() async {
    try {
      final skills = await _skillRepository.getUserSkills();
      if (mounted) {
        setState(() {
          _userSkills = skills;
        });
      }
    } catch (e) {
      print('Error loading user skills: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await _userRepository.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Future<void> _editProfile() async {
    // This would navigate to an edit profile page in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile coming soon!')),
    );
  }

  Future<void> _refreshProfile() async {
    await Future.wait([
      _loadUserData(),
      _loadUserSkills(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'profilePic',
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(_userProfilePic),
                            onBackgroundImageError: (_, __) {},
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '$_userRating',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.work_outline,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '$_totalJobsDone jobs',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editProfile,
                  tooltip: 'Edit Profile',
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _signOut,
                  tooltip: 'Sign Out',
                ),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'About'),
                    Tab(text: 'My Skills'),
                    Tab(text: 'Settings'),
                  ],
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondaryColor,
                  indicatorColor: AppTheme.primaryColor,
                ),
              ),
              pinned: true,
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              // About tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userBio,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoItem(Icons.email, 'Email', _userEmail),
                    _buildInfoItem(Icons.phone, 'Phone', _userPhone),
                    _buildInfoItem(
                        Icons.location_on, 'Location', _userLocation),
                    const SizedBox(height: 24),
                    const Text(
                      'Account Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(),
                  ],
                ),
              ),

              // My Skills tab
              _buildMySkillsTab(),

              // Settings tab
              _buildSettingsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Skills', _userSkills.length.toString()),
          _buildStatItem('Jobs Done', _totalJobsDone.toString()),
          _buildStatItem('Rating', '$_userRating/5.0'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMySkillsTab() {
    return _userSkills.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_off_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'You haven\'t added any skills yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add your skills to get hired',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Add Skill',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddSkillPage(),
                      ),
                    ).then((_) {
                      // Refresh skills when returning
                      _loadUserSkills();
                    });
                  },
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _userSkills.length,
            itemBuilder: (context, index) {
              final skill = _userSkills[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SkillCard(
                  skill: skill,
                  onTap: () {
                    // Would navigate to edit skill page
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Edit ${skill.title} coming soon!')),
                    );
                  },
                ),
              );
            },
          );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            Icons.person,
            'Edit Profile',
            'Update your personal information',
            () => _editProfile(),
          ),
          _buildSettingItem(
            Icons.notifications,
            'Notifications',
            'Manage your notification preferences',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notification settings coming soon!')),
              );
            },
          ),
          _buildSettingItem(
            Icons.lock,
            'Privacy & Security',
            'Manage your privacy and security settings',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy settings coming soon!')),
              );
            },
          ),
          _buildSettingItem(
            Icons.payment,
            'Payment Methods',
            'Manage your payment methods',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment settings coming soon!')),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'App Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            Icons.language,
            'Language',
            'Change app language',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings coming soon!')),
              );
            },
          ),
          _buildSettingItem(
            Icons.dark_mode,
            'Theme',
            'Change app theme',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme settings coming soon!')),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            Icons.help,
            'Help & Support',
            'Get help with using the app',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help center coming soon!')),
              );
            },
          ),
          _buildSettingItem(
            Icons.policy,
            'Terms & Policies',
            'View our terms and policies',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms page coming soon!')),
              );
            },
          ),
          _buildSettingItem(
            Icons.info,
            'About Skill Hub',
            'Learn more about Skill Hub',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('About page coming soon!')),
              );
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Sign Out',
            onPressed: _signOut,
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// This delegate is used for the tab bar to stay at the top when scrolling
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
