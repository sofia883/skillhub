import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:skill_hub/core/theme/app_theme.dart';
import 'package:skill_hub/features/auth/data/repositories/user_repository.dart';
import 'package:skill_hub/features/auth/presentation/pages/login_screen.dart';
import 'package:skill_hub/features/home/data/repositories/skill_repository.dart';
import 'package:skill_hub/features/home/domain/entities/skill.dart';
import 'package:skill_hub/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:skill_hub/features/skills/presentation/pages/add_skill_page.dart';
import 'package:skill_hub/features/skills/presentation/pages/edit_skill_page.dart';

class ProfilePage extends StatefulWidget {
  final int initialTab;

  const ProfilePage({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _skillRepository = SkillRepository();
  final _firestore = FirebaseFirestore.instance;
  final _userRepository = UserRepository();
  bool _isLoading = false;

  // Tab controller
  late TabController _tabController;

  // User skills
  List<Map<String, dynamic>> _skills = [];
  StreamSubscription<List<Map<String, dynamic>>>? _skillsSubscription;

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
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadUserData();
    _initializeSkillsStream();
  }

  void _initializeSkillsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Cancel existing subscription if any
      _skillsSubscription?.cancel();

      // Create new subscription
      _skillsSubscription =
          _skillRepository.getUserSkills(user.uid).listen((skills) {
        if (mounted) {
          setState(() {
            _skills = skills;
          });
        }
      }, onError: (error) {
        debugPrint('Error loading skills: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading skills: $error')),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _skillsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load basic info from Firebase Auth
        setState(() {
          _userName = user.displayName ?? 'User';
          _userEmail = user.email ?? '';
          _userProfilePic = user.photoURL ?? 'https://via.placeholder.com/150';
        });

        // Load additional info from Firestore
        try {
          final userData = await _userRepository.getUserData(user.uid);
          if (userData != null) {
            setState(() {
              _userName = userData['displayName'] ?? _userName;
              _userBio = userData['bio'] ?? _userBio;
              _userLocation = userData['location'] ?? _userLocation;
              _userPhone = userData['phone'] ?? _userPhone;
              _userRating = (userData['rating'] ?? 0.0).toDouble();
              _totalJobsDone = userData['jobsDone'] ?? 0;
            });
          }
        } catch (e) {
          debugPrint('Error loading user data from Firestore: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  Future<void> _refreshProfile() async {
    await _loadUserData();
    _initializeSkillsStream();
  }

  void _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userData = await _userRepository.getUserData(user.uid);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfilePage(
            initialName: _userName,
            initialBio: _userBio,
            initialLocation: _userLocation,
            initialProfilePic: _userProfilePic,
            initialCountry: userData?['country'],
            initialState: userData?['state'],
            initialCity: userData?['city'],
            initialHouseNo: userData?['houseNo'],
          ),
        ),
      ).then((_) => _refreshProfile());
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Delete user data from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
      }

      // Delete user account
      await _userRepository.deleteAccount();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

  void _showDeleteSkillDialog(Skill skill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Skill'),
        content: Text(
            'Are you sure you want to delete "${skill.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSkill(skill.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSkill(String skillId) async {
    try {
      final success = await _skillRepository.deleteSkill(skillId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting skill: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        _userProfilePic != 'https://via.placeholder.com/150'
                            ? NetworkImage(_userProfilePic)
                            : null,
                    child: _userProfilePic == 'https://via.placeholder.com/150'
                        ? Text(
                            _userName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'Information'),
                Tab(text: 'My Skills'),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Information Tab
                ListView(
                  children: _buildProfileOptions(),
                ),

                // Skills Tab
                RefreshIndicator(
                  onRefresh: _refreshProfile,
                  child: user != null
                      ? Builder(
                          builder: (context) {
                            if (_isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'My Skills (${_skills.length})',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const AddSkillPage(),
                                            ),
                                          ).then(
                                              (_) => _initializeSkillsStream());
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Skill'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: _skills.isEmpty
                                      ? const Center(
                                          child: Text('No skills added yet'),
                                        )
                                      : ListView.separated(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20),
                                          itemCount: _skills.length,
                                          separatorBuilder: (context, index) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, index) {
                                            final skill = _skills[index];
                                            return ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              leading: Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                      skill['imageUrl'] ??
                                                          'https://via.placeholder.com/50',
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                skill['title'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Text(
                                                skill['description'] ?? '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon:
                                                        const Icon(Icons.edit),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              EditSkillPage(
                                                            skill: Skill(
                                                              id: skill['id'],
                                                              title: skill[
                                                                  'title'],
                                                              description: skill[
                                                                  'description'],
                                                              category: skill[
                                                                  'category'],
                                                              price: double.parse(
                                                                  skill['price']
                                                                      .toString()),
                                                              rating: skill[
                                                                          'rating']
                                                                      ?.toDouble() ??
                                                                  0.0,
                                                              provider: skill[
                                                                      'provider'] ??
                                                                  user.displayName ??
                                                                  'Unknown Provider',
                                                              imageUrl: skill[
                                                                      'imageUrl'] ??
                                                                  'https://via.placeholder.com/150',
                                                              createdAt: skill[
                                                                          'createdAt']
                                                                      ?.toDate() ??
                                                                  DateTime
                                                                      .now(),
                                                              userId: user.uid,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red),
                                                    onPressed: () =>
                                                        _showDeleteSkillDialog(
                                                            Skill(
                                                      id: skill['id'],
                                                      title: skill['title'],
                                                      description:
                                                          skill['description'],
                                                      category:
                                                          skill['category'],
                                                      price: double.parse(
                                                          skill['price']
                                                              .toString()),
                                                      rating: skill['rating']
                                                              ?.toDouble() ??
                                                          0.0,
                                                      provider: skill[
                                                              'provider'] ??
                                                          user.displayName ??
                                                          'Unknown Provider',
                                                      imageUrl: skill[
                                                              'imageUrl'] ??
                                                          'https://via.placeholder.com/150',
                                                      createdAt:
                                                          skill['createdAt']
                                                                  ?.toDate() ??
                                                              DateTime.now(),
                                                      userId: user.uid,
                                                    )),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            );
                          },
                        )
                      : const Center(
                          child: Text('Please log in to view your skills'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProfileOptions() {
    return [
      const Divider(height: 1),
      ListTile(
        leading:
            Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
        title: const Text('Name'),
        subtitle: Text(_userName),
        trailing: const Icon(Icons.chevron_right),
        onTap: _editProfile,
      ),
      const Divider(height: 1),
      ListTile(
        leading:
            Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
        title: const Text('Email'),
        subtitle: Text(_userEmail),
      ),
      const Divider(height: 1),
      ListTile(
        leading:
            Icon(Icons.phone_outlined, color: Theme.of(context).primaryColor),
        title: const Text('Phone Number'),
        subtitle: Text(_userPhone),
        trailing: const Icon(Icons.chevron_right),
        onTap: _editProfile,
      ),
      const Divider(height: 1),
      ListTile(
        leading: Icon(Icons.location_on_outlined,
            color: Theme.of(context).primaryColor),
        title: const Text('Location'),
        subtitle: Text(_userLocation),
        trailing: const Icon(Icons.chevron_right),
        onTap: _editProfile,
      ),
      if (_userBio != 'No bio available') ...[
        const Divider(height: 1),
        ListTile(
          leading:
              Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
          title: const Text('About Me'),
          subtitle: Text(_userBio),
          trailing: const Icon(Icons.chevron_right),
          onTap: _editProfile,
        ),
      ],
      const Divider(height: 1),
      ListTile(
        leading:
            Icon(Icons.star_outline, color: Theme.of(context).primaryColor),
        title: const Text('Rating'),
        subtitle: Text('${_userRating.toStringAsFixed(1)} / 5.0'),
      ),
      const Divider(height: 1),
      ListTile(
        leading:
            Icon(Icons.work_outline, color: Theme.of(context).primaryColor),
        title: const Text('Jobs Completed'),
        subtitle: Text('$_totalJobsDone jobs'),
      ),
      const Divider(height: 1),
      // Settings section
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Settings',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ListTile(
        leading: Icon(Icons.delete_outline, color: Colors.red),
        title: const Text('Clear Cache'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Handle clear cache
        },
      ),
      const Divider(height: 1),
      ListTile(
        leading: Icon(Icons.history, color: Theme.of(context).primaryColor),
        title: const Text('Clear History'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Handle clear history
        },
      ),
      const Divider(height: 1),
      ListTile(
        leading: Icon(Icons.logout, color: Colors.red),
        title: const Text('Sign Out'),
        onTap: _signOut,
      ),
      const Divider(height: 1),
    ];
  }
}
