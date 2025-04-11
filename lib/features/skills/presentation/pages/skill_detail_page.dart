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
      appBar: AppBar(
        title: Text(widget.skill.title),
        elevation: 0,
        actions: [
          if (_isCurrentUserProvider)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Navigate to edit skill page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit skill coming soon')),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          RefreshIndicator(
            onRefresh: () => _loadSkillDetails(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Network error banner
                  if (_hasNetworkError)
                    Container(
                      width: double.infinity,
                      color: Colors.orange.shade100,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Network error: Showing limited information',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _retryLoading,
                            child: const Text('RETRY'),
                          ),
                        ],
                      ),
                    ),

                  // Image gallery with error handling
                  _imageUrls.isNotEmpty
                      ? Builder(builder: (context) {
                          return _hasNetworkError
                              ? Container(
                                  height: 250,
                                  width: double.infinity,
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Images unavailable offline',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ImageGallery(imageUrls: _imageUrls);
                        })
                      : Container(
                          height: 250,
                          width: double.infinity,
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image_not_supported_outlined,
                                size: 50,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No images available',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.skill.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Price and buttons in one row
                        Row(
                          children: [
                            // Price tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '₹${widget.skill.price.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Call button - MADE LARGER AND MORE PROMINENT
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height:
                                    44, // Fixed height for better visibility
                                child: ElevatedButton.icon(
                                  onPressed: _callProvider,
                                  icon: const Icon(Icons.call,
                                      color: Colors.white, size: 20),
                                  label: const Text('CALL',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.green, // Green for call button
                                    elevation: 3, // Add shadow
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Chat button - ENHANCED WITH MESSAGE INDICATOR
                            Expanded(
                              flex: 1,
                              child: Stack(
                                children: [
                                  SizedBox(
                                    height:
                                        44, // Fixed height for better visibility
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _chatWithProvider,
                                      icon: const Icon(Icons.chat_bubble,
                                          color: Colors.white, size: 20),
                                      label: const Text('CHAT',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors
                                            .deepPurple, // More distinctive color
                                        elevation: 4, // Increased shadow
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  // Message notification indicator
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Text('',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Category and rating
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.skill.category,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_skillData.containsKey('subcategory') &&
                                _skillData['subcategory'] is String &&
                                (_skillData['subcategory'] as String)
                                    .isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _skillData['subcategory'],
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.skill.rating > 0
                                  ? widget.skill.rating.toStringAsFixed(1)
                                  : 'New',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Provider info
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                _buildProviderAvatar(theme),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _providerData.containsKey(
                                                    'displayName') &&
                                                (_providerData['displayName']
                                                            as String?)
                                                        ?.isNotEmpty ==
                                                    true
                                            ? _providerData['displayName']
                                            : widget.skill.provider,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_providerData
                                              .containsKey('location') &&
                                          (_providerData['location'] as String?)
                                                  ?.isNotEmpty ==
                                              true)
                                        Text(
                                          _providerData['location'],
                                          style: theme.textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Description
                        Text(
                          'Description',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.skill.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Phone number if available
                        if (widget.skill.phoneNumber != null &&
                            widget.skill.phoneNumber!.isNotEmpty) ...[
                          Text(
                            'Contact',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.skill.phoneNumber!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Location
                        if (_skillData.containsKey('location') ||
                            widget.skill.location != null) ...[
                          Text(
                            'Location',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _skillData.containsKey('location') &&
                                          (_skillData['location'] as String?)
                                                  ?.isNotEmpty ==
                                              true
                                      ? _skillData['location']
                                      : widget.skill.location ??
                                          'Location not specified',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Availability
                        if (_skillData.containsKey('availability') &&
                            (_skillData['availability'] as String?)
                                    ?.isNotEmpty ==
                                true) ...[
                          Text(
                            'Availability',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _skillData['availability'],
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Online availability
                        if (_skillData.containsKey('isOnline')) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.computer,
                                color: _skillData['isOnline'] == true
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _skillData['isOnline'] == true
                                    ? 'Available Online'
                                    : 'In-person Only',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _skillData['isOnline'] == true
                                      ? theme.colorScheme.primary
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Add extra space at the bottom for the bottom navigation bar
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator overlay
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.7),
              width: double.infinity,
              height: double.infinity,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      // Always show the bottom navigation bar with chat and call buttons
      bottomNavigationBar: Container(
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
        // Only show Book Now button in the bottom bar
        child: CustomButton(
          text: 'Book Now',
          onPressed: _bookService,
          backgroundColor: theme.colorScheme.primary,
          icon: Icons.calendar_today,
        ),
      ),
    );
  }
}
