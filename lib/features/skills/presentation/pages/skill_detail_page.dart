import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_hub/core/widgets/custom_button.dart';
import 'package:skill_hub/features/home/domain/entities/skill.dart';
import 'package:skill_hub/features/skills/presentation/widgets/image_gallery.dart';
import 'package:skill_hub/features/booking/presentation/pages/booking_page.dart';
import 'package:skill_hub/features/chat/presentation/pages/chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SkillDetailPage extends StatefulWidget {
  final Skill skill;

  const SkillDetailPage({super.key, required this.skill});

  @override
  SkillDetailPageState createState() => SkillDetailPageState();
}

class SkillDetailPageState extends State<SkillDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic> _skillData = {};
  Map<String, dynamic> _providerData = {};
  bool _isCurrentUserProvider = false;
  List<String> _imageUrls = [];
  bool _hasNetworkError = false;

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    _imageUrls = [widget.skill.imageUrl];
    _loadSkillDetails();
  }

  Future<void> _loadSkillDetails() async {
    // Set a timeout for loading data
    const timeout = Duration(seconds: 5);

    setState(() {
      _isLoading = true;
      _hasNetworkError = false;
    });

    // Start a timer to ensure we don't show loading indicator for too long
    Future.delayed(timeout).then((_) {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          debugPrint('Loading timed out, showing basic skill data');
        });
      }
    });

    try {
      // Check if current user is the provider
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _isCurrentUserProvider =
            widget.skill.provider == currentUser.displayName ||
                widget.skill.provider == currentUser.email ||
                (widget.skill.userId != null &&
                    widget.skill.userId == currentUser.uid);

        // Debug print to check if this condition is working
        debugPrint(
            'Current user: ${currentUser.displayName} (${currentUser.email})');
        debugPrint('Skill provider: ${widget.skill.provider}');
        debugPrint('Skill userId: ${widget.skill.userId}');
        debugPrint('Is current user the provider? $_isCurrentUserProvider');
      } else {
        // If no user is logged in, they're definitely not the provider
        _isCurrentUserProvider = false;
      }

      // Try to get full skill data from Firestore with timeout
      try {
        final skillDoc = await FirebaseFirestore.instance
            .collection('skills')
            .doc(widget.skill.id)
            .get()
            .timeout(timeout);

        if (skillDoc.exists) {
          _skillData = skillDoc.data() ?? {};

          // Get image URLs if available
          if (_skillData.containsKey('imageUrls') &&
              _skillData['imageUrls'] is List &&
              (_skillData['imageUrls'] as List).isNotEmpty) {
            _imageUrls = List<String>.from(_skillData['imageUrls']);
          } else if (_skillData.containsKey('imageUrl') &&
              _skillData['imageUrl'] is String &&
              (_skillData['imageUrl'] as String).isNotEmpty) {
            _imageUrls = [_skillData['imageUrl']];
          }

          // Try to get provider data with timeout
          if (_skillData.containsKey('providerId') &&
              _skillData['providerId'] is String &&
              (_skillData['providerId'] as String).isNotEmpty) {
            try {
              final providerDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(_skillData['providerId'])
                  .get()
                  .timeout(timeout);

              if (providerDoc.exists) {
                _providerData = providerDoc.data() ?? {};
              }
            } catch (e) {
              debugPrint('Error fetching provider data: $e');
              // Continue without provider data
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching skill data: $e');
        setState(() {
          _hasNetworkError = true;
        });
        // Show a snackbar with the error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network error: Using basic skill data'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        // Continue with the basic skill data we already have
      }
    } catch (e) {
      debugPrint('Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _callProvider() async {
    // Check if the current user is the provider
    if (_isCurrentUserProvider) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This is your own skill listing')),
        );
      }
      return;
    }

    // Get provider phone number
    String? phoneNumber;

    // First check if the skill has a phone number
    if (widget.skill.phoneNumber != null &&
        widget.skill.phoneNumber!.isNotEmpty) {
      phoneNumber = widget.skill.phoneNumber;
    }
    // Then check if we have it in the provider data
    else if (_providerData.containsKey('phone') &&
        _providerData['phone'] is String &&
        (_providerData['phone'] as String).isNotEmpty) {
      phoneNumber = _providerData['phone'];
    }
    // Finally check if it's in the skill data
    else if (_skillData.containsKey('phoneNumber') &&
        _skillData['phoneNumber'] is String &&
        (_skillData['phoneNumber'] as String).isNotEmpty) {
      phoneNumber = _skillData['phoneNumber'];
    }

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      try {
        final Uri uri = Uri.parse('tel:$phoneNumber');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not launch phone call')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')),
        );
      }
    }
  }

  Future<void> _chatWithProvider() async {
    // Check if the current user is the provider
    if (_isCurrentUserProvider) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This is your own skill listing')),
        );
      }
      return;
    }

    // Get provider ID
    String? providerId;
    String providerName = widget.skill.provider;

    if (widget.skill.userId != null && widget.skill.userId!.isNotEmpty) {
      providerId = widget.skill.userId;
    } else if (_skillData.containsKey('providerId') ||
        _skillData.containsKey('userId')) {
      providerId = _skillData['providerId'] ?? _skillData['userId'];
    }

    // Get provider name from provider data if available
    if (_providerData.containsKey('displayName') &&
        _providerData['displayName'] is String &&
        (_providerData['displayName'] as String).isNotEmpty) {
      providerName = _providerData['displayName'];
    }

    if (providerId != null && providerId.isNotEmpty) {
      // Check if user is logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please sign in to chat with providers')),
          );
        }
        return;
      }

      // Navigate to chat screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              providerId:
                  providerId!, // Non-null assertion is safe here because we check above
              providerName: providerName,
              skill: widget.skill,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot start chat with this provider')),
        );
      }
    }
  }

  void _bookService() {
    // Check if the current user is the provider
    if (_isCurrentUserProvider) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot book your own skill')),
        );
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPage(skill: widget.skill),
      ),
    );
  }

  void _retryLoading() {
    setState(() {
      _hasNetworkError = false;
    });
    _loadSkillDetails();
  }

  // Safely get provider initial
  String _getProviderInitial() {
    try {
      if (widget.skill.provider.isNotEmpty) {
        return widget.skill.provider[0].toUpperCase();
      }
    } catch (e) {
      debugPrint('Error getting provider initial: $e');
    }
    return '?';
  }

  // Safely get provider photo URL
  Widget _buildProviderAvatar(ThemeData theme) {
    // Check if we have a valid photo URL
    bool hasValidPhotoUrl = false;
    String? photoUrl;

    try {
      if (_providerData.containsKey('photoURL') &&
          _providerData['photoURL'] is String &&
          (_providerData['photoURL'] as String).isNotEmpty) {
        photoUrl = _providerData['photoURL'];
        hasValidPhotoUrl = true;
      }
    } catch (e) {
      debugPrint('Error checking photo URL: $e');
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      // Only use NetworkImage if we have a valid URL
      backgroundImage: hasValidPhotoUrl ? NetworkImage(photoUrl!) : null,
      // Show text avatar if no valid image
      child: hasValidPhotoUrl
          ? null
          : Text(
              _getProviderInitial(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light gray background like LinkedIn
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.skill.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isCurrentUserProvider)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black87),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit skill coming soon')),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadSkillDetails(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider info with large avatar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            _getProviderInitial(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _providerData.containsKey('displayName') &&
                                        (_providerData['displayName']
                                                    as String?)
                                                ?.isNotEmpty ==
                                            true
                                    ? _providerData['displayName']
                                    : widget.skill.provider,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.skill.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (_skillData.containsKey('location'))
                                Text(
                                  _skillData['location'],
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.skill.rating > 0
                                        ? '${widget.skill.rating.toStringAsFixed(1)} Rating'
                                        : 'New Provider',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // About Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.skill.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Service Details Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      Icons.work_outline,
                      'Category',
                      widget.skill.category,
                    ),
                    if (_skillData.containsKey('availability'))
                      _buildDetailRow(
                        context,
                        Icons.access_time,
                        'Availability',
                        _skillData['availability'],
                      ),
                    _buildDetailRow(
                      context,
                      Icons.location_on_outlined,
                      'Location',
                      _skillData.containsKey('location')
                          ? _skillData['location']
                          : widget.skill.location ?? 'Location not specified',
                    ),
                    _buildDetailRow(
                      context,
                      Icons.computer_outlined,
                      'Service Type',
                      _skillData['isOnline'] == true
                          ? 'Available Online'
                          : 'In-person Only',
                    ),
                    _buildDetailRow(
                      context,
                      Icons.payments_outlined,
                      'Price',
                      '₹${widget.skill.price.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100), // Space for bottom bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: !_isCurrentUserProvider
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Connect',
                      onPressed: _chatWithProvider,
                      backgroundColor: theme.colorScheme.primary,
                      icon: Icons.person_add_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Message',
                      onPressed: _chatWithProvider,
                      backgroundColor: Colors.white,
                      textColor: theme.colorScheme.primary,
                      borderColor: theme.colorScheme.primary,
                      icon: Icons.message_outlined,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
