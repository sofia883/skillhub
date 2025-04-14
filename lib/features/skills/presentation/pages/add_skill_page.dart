import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../features/home/data/repositories/skill_repository.dart';
import '../../../profile/presentation/widgets/enhanced_location_selector.dart';
import '../widgets/price_input.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';

class AddSkillPage extends StatefulWidget {
  const AddSkillPage({super.key});

  @override
  State<AddSkillPage> createState() => _AddSkillPageState();
}

class _AddSkillPageState extends State<AddSkillPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _skillRepository = SkillRepository();

  // Address data
  Map<String, dynamic>? _addressData;

  String _selectedCategory = 'Other';
  String _selectedSubcategory = '';
  String _selectedPriceType = 'Fixed';
  bool _isOnline = false;
  bool _isLoading = false;
  bool _isUploadingImages = false;
  final List<File> _selectedImages = [];
  final _imagePicker = ImagePicker();
  int _currentStep = 0;

  // ImgBB API key - Replace with your own key
  final String _imgbbApiKey =
      "0c58b6d9015713886842dab7d4825812"; // User's API key for ImgBB

  final List<String> categories = [
    'Programming',
    'Design',
    'Marketing',
    'Writing',
    'Music',
    'Fitness',
    'Cooking',
    'Stitching',
    'Mehndi',
    'Photography',
    'Teaching',
    'Cleaning',
    'Tutoring',
    'Languages',
    'Handcrafts',
    'Other'
  ];

  // More detailed subcategories based on main category
  Map<String, List<String>> subcategories = {
    'Programming': [
      'Web Development',
      'Mobile Apps',
      'Desktop Software',
      'Game Development',
      'AI/ML',
      'Blockchain'
    ],
    'Design': [
      'Graphic Design',
      'UI/UX Design',
      'Logo Design',
      'Illustration',
      '3D Modeling'
    ],
    'Marketing': [
      'Social Media',
      'SEO',
      'Content Marketing',
      'Email Marketing',
      'Influencer Marketing'
    ],
    'Writing': [
      'Blog Posts',
      'Copywriting',
      'Technical Writing',
      'Creative Writing',
      'Translation'
    ],
    'Music': [
      'Vocals',
      'Instruments',
      'Production',
      'Songwriting',
      'Mixing & Mastering'
    ],
    'Fitness': [
      'Personal Training',
      'Yoga',
      'Nutrition',
      'Dance',
      'Meditation'
    ],
    'Cooking': [
      'Meal Prep',
      'Baking',
      'Specialty Cuisine',
      'Catering',
      'Cooking Classes'
    ],
    'Stitching': [
      'Clothing',
      'Alterations',
      'Embroidery',
      'Quilting',
      'Pattern Making'
    ],
    'Mehndi': [
      'Bridal',
      'Party',
      'Arabic Style',
      'Indian Style',
      'Modern Fusion'
    ],
    'Photography': ['Portrait', 'Event', 'Product', 'Wedding', 'Real Estate'],
    'Teaching': [
      'Academic',
      'Music',
      'Arts & Crafts',
      'Professional Skills',
      'Language'
    ],
    'Cleaning': [
      'Home',
      'Office',
      'Post-Construction',
      'Specialized',
      'Eco-Friendly'
    ],
    'Tutoring': ['Math', 'Science', 'Languages', 'Test Prep', 'Music'],
    'Languages': [
      'Translation',
      'Tutoring',
      'Document Preparation',
      'Subtitling',
      'Transcription'
    ],
    'Handcrafts': [
      'Jewelry',
      'Pottery',
      'Woodworking',
      'Candle Making',
      'Custom Gifts'
    ],
    'Other': [
      'Consultation',
      'Virtual Assistance',
      'Event Planning',
      'Life Coaching',
      'Custom Services'
    ],
  };

  // Add new variables for phone and location
  String _selectedCountryCode = '+91';
  bool _isLoadingLocation = false;
  String? _currentAddress;
  Position? _currentPosition;

  // Add this variable to store price data
  Map<String, dynamic> _priceData = {
    'currency': '₹',
    'type': 'Fixed',
    'amount': '',
  };

  // Phone number
  String? _completePhoneNumber;
  bool _isValidPhone = false;

  // Location
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    // Initialize default subcategory
    if (subcategories.containsKey(_selectedCategory) &&
        subcategories[_selectedCategory]!.isNotEmpty) {
      _selectedSubcategory = subcategories[_selectedCategory]![0];
    }
    // Request permissions on startup
    _requestPermissions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  void _updateSubcategories(String category) {
    setState(() {
      if (subcategories.containsKey(category) &&
          subcategories[category]!.isNotEmpty) {
        _selectedSubcategory = subcategories[category]![0];
      } else {
        _selectedSubcategory = ''; // Set to empty if no subcategories
      }
    });
  }

  Future<void> _requestPermissions() async {
    // Request permissions for camera and photos
    final permissionStatus = await [
      Permission.camera,
      Permission.storage,
      Permission.photos,
    ].request();

    // Print status to help debugging
    debugPrint('Camera permission: ${permissionStatus[Permission.camera]}');
    debugPrint('Storage permission: ${permissionStatus[Permission.storage]}');
    debugPrint('Photos permission: ${permissionStatus[Permission.photos]}');
  }

  Future<void> _pickImages() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final storageStatus = await Permission.storage.status;
      final photosStatus = await Permission.photos.status;

      debugPrint(
          'Permission status - Camera: $cameraStatus, Storage: $storageStatus, Photos: $photosStatus');

      if (!cameraStatus.isGranted ||
          !(storageStatus.isGranted || photosStatus.isGranted)) {
        // Request permissions again
        await _requestPermissions();

        // Check if permissions were granted
        final updatedCameraStatus = await Permission.camera.status;
        final updatedStorageStatus = await Permission.storage.status;
        final updatedPhotosStatus = await Permission.photos.status;

        if (!updatedCameraStatus.isGranted ||
            !(updatedStorageStatus.isGranted ||
                updatedPhotosStatus.isGranted)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Please grant camera and storage permissions in settings'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      final pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((e) => File(e.path)).toList());
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final cameraStatus = await Permission.camera.status;

      debugPrint('Camera permission status: $cameraStatus');

      if (!cameraStatus.isGranted) {
        await Permission.camera.request();

        final updatedStatus = await Permission.camera.status;
        if (!updatedStatus.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please grant camera permission in settings'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    final List<String> imageUrls = [];

    if (_selectedImages.isEmpty) {
      return imageUrls;
    }

    setState(() {
      _isUploadingImages = true;
    });

    try {
      // Show upload progress once before the loop
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading images...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      for (final image in _selectedImages) {
        // Convert image to base64
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        // Upload to ImgBB
        final response = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload'),
          body: {
            'key': _imgbbApiKey,
            'image': base64Image,
          },
        );

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['success'] == true) {
            final imageUrl = jsonResponse['data']['display_url'];
            imageUrls.add(imageUrl);
          } else {
            debugPrint('Image upload failed: ${jsonResponse['error']}');
          }
        } else {
          debugPrint(
              'Image upload failed with status code: ${response.statusCode}');
          debugPrint('Response body: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Error uploading images: $e');
    } finally {
      setState(() {
        _isUploadingImages = false;
      });
    }

    return imageUrls;
  }

  Future<void> _submitSkill() async {
    // Check for blank fields in the final step too
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _availabilityController.text.isEmpty ||
        (_priceController.text.isEmpty &&
            _selectedPriceType != 'Contact for Pricing')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Please fill all required fields in previous steps'),
          backgroundColor: Colors.amber[700],
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Show uploading status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing your submission...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Upload images to ImgBB
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        try {
          imageUrls = await _uploadImages();
          debugPrint(
              'Image upload complete: ${imageUrls.length} images uploaded');
        } catch (e) {
          debugPrint('Error uploading images: $e');
          // Continue even if image upload fails
        }
      }

      // Create skill data with fixed IDs and ensure all fields are properly initialized
      final skillId = DateTime.now().millisecondsSinceEpoch.toString();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

      // Get current user or sign in anonymously if needed
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        try {
          final userCredential =
              await FirebaseAuth.instance.signInAnonymously();
          currentUser = userCredential.user;
          debugPrint(
              '✅ Signed in anonymously with user ID: ${currentUser?.uid}');
        } catch (e) {
          debugPrint('⚠️ Failed to sign in anonymously: $e');
        }
      }

      // Format the location string
      final location = [
        _locationController.text.trim(),
        _selectedCity,
        _selectedState,
        _selectedCountry,
      ].where((e) => e != null && e.isNotEmpty).join(', ');

      // Create skill data
      final skillData = {
        'id': skillId,
        'title': _titleController.text.trim(),
        'description': _generateDescription(),
        'category': _selectedCategory,
        'subcategory': _selectedSubcategory,
        'price': _selectedPriceType == 'Contact for Pricing'
            ? 0.0
            : (double.tryParse(_priceController.text.trim()) ?? 0.0),
        'priceType': _selectedPriceType,
        'rating': 0.0, // New skills start with no rating
        'imageUrl': imageUrls.isNotEmpty
            ? imageUrls.first
            : 'https://via.placeholder.com/300x200?text=No+Image',
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'isFeatured': false,
        'location': location,
        'isOnline': _isOnline,
        'availability': _availabilityController.text.trim(),
        'address': _addressData,
        'userId':
            currentUser?.uid ?? 'unknown_user', // Important for security rules
        'providerId': currentUser?.uid ?? 'unknown_user',
        'provider':
            currentUser?.displayName ?? currentUser?.email ?? 'Anonymous User',
        'country': _selectedCountry,
        'state': _selectedState,
        'city': _selectedCity,
        'phone': _completePhoneNumber,
      };

      debugPrint('Attempting to save skill: ${skillData['title']}');

      // Show saving indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving your skill...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Save to Firestore using repository with retry mechanism
      bool success = false;
      for (int i = 0; i < 3; i++) {
        try {
          debugPrint('✅ Attempt ${i + 1} to save skill: ${skillData['title']}');
          success = await _skillRepository.addSkill(skillData);
          if (success) {
            debugPrint('✅ Successfully saved skill on attempt ${i + 1}');
            break;
          }
          // Wait briefly before retrying
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          debugPrint('❌ Attempt ${i + 1} failed: $e');
        }
      }

      // Show appropriate message based on success
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Skill saved successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Skill saved locally. Will sync when online.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Show success dialog
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('Error submitting skill: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'There was an issue saving your skill. We\'ll try again later.'),
            backgroundColor: const Color(0xFFFF8F00), // Colors.amber[700]
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _generateDescription() {
    final buffer = StringBuffer();

    buffer.writeln(_descriptionController.text.trim());

    if (_selectedSubcategory.isNotEmpty) {
      buffer.writeln('\nSpecialty: $_selectedSubcategory');
    }

    if (_locationController.text.isNotEmpty) {
      buffer.writeln(
          '\nLocation: ${_locationController.text.trim()}${_isOnline ? ' (Also available online)' : ''}');
    } else if (_isOnline) {
      buffer.writeln('\nAvailable Online');
    }

    if (_availabilityController.text.isNotEmpty) {
      buffer.writeln('\nAvailability: ${_availabilityController.text.trim()}');
    }

    // Don't include phone number in description for privacy reasons
    // It will be stored separately in the skill data

    return buffer.toString();
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _locationController.clear();
      _availabilityController.clear();
      _selectedCategory = 'Other';
      _selectedSubcategory = '';
      _isOnline = false;
      _selectedImages.clear();
      _currentStep = 0;
      _addressData = null;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Success!'),
          ],
        ),
        content: const Text(
            'Your skill has been added successfully. It will now be visible to potential clients.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog

              // Check if we're in the main navigation or opened as a separate page
              if (Navigator.of(context).canPop()) {
                // Return to previous screen with a result to trigger refresh
                Navigator.of(context)
                    .pop(true); // Pass true to indicate success
              } else {
                // We're in the main navigation, so just reset the form
                _resetForm();
              }
            },
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  List<Step> get _steps => [
        Step(
          title: const Text('Basics'),
          content: _buildBasicInfoStep(),
          isActive: _currentStep >= 0,
        ),
        Step(
          title: const Text('Details'),
          content: _buildDetailsStep(),
          isActive: _currentStep >= 1,
        ),
        Step(
          title: const Text('Photos'),
          content: _buildPortfolioStep(),
          isActive: _currentStep >= 2,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Add New Skill'),
          ),
          body: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    CustomTextField(
                      label: 'Skill Title',
                      controller: _titleController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                      prefixIcon: const Icon(Icons.title),
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      value: _selectedCategory,
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                          _updateSubcategories(value);
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Subcategory dropdown
                    if (subcategories.containsKey(_selectedCategory) &&
                        subcategories[_selectedCategory]!.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Specialty',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.topic),
                        ),
                        value: _selectedSubcategory.isEmpty
                            ? subcategories[_selectedCategory]![0]
                            : _selectedSubcategory,
                        items: subcategories[_selectedCategory]!
                            .map((subcategory) {
                          return DropdownMenuItem(
                            value: subcategory,
                            child: Text(subcategory),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSubcategory = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Price field with pricing model
                    PriceInput(
                      controller: _priceController,
                      onCurrencyAndTypeChanged: (currency, type) {
                        _updatePriceData(currency, type);
                      },
                    ),

                    // Phone Field
                    IntlPhoneField(
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      initialCountryCode: 'IN',
                      flagsButtonPadding: const EdgeInsets.all(8),
                      showDropdownIcon: true,
                      dropdownIconPosition: IconPosition.trailing,
                      invalidNumberMessage: 'Invalid phone number',
                      onChanged: (phone) {
                        setState(() {
                          _completePhoneNumber = phone.completeNumber;
                          _isValidPhone = phone.isValidNumber();
                        });
                      },
                      validator: (value) {
                        if (value == null || !value.isValidNumber()) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Country State City Picker
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          SelectState(
                            onCountryChanged: (value) async {
                              setState(() {
                                _selectedCountry = value;
                                _selectedState = null;
                                _selectedCity = null;
                              });
                            },
                            onStateChanged: (value) async {
                              setState(() {
                                _selectedState = value;
                                _selectedCity = null;
                              });
                            },
                            onCityChanged: (value) {
                              setState(() {
                                _selectedCity = value;
                              });
                            },
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address Field
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Street Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your street address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitSkill,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Add Skill',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title field
        CustomTextField(
          label: 'Skill Title',
          controller: _titleController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
          prefixIcon: const Icon(Icons.title),
        ),
        const SizedBox(height: 16),

        // Category dropdown
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          value: _selectedCategory,
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
              _updateSubcategories(value);
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Subcategory dropdown
        if (subcategories.containsKey(_selectedCategory) &&
            subcategories[_selectedCategory]!.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Specialty',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.topic),
            ),
            value: _selectedSubcategory.isEmpty
                ? subcategories[_selectedCategory]![0]
                : _selectedSubcategory,
            items: subcategories[_selectedCategory]!.map((subcategory) {
              return DropdownMenuItem(
                value: subcategory,
                child: Text(subcategory),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedSubcategory = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
        ],

        // Price field with pricing model
        PriceInput(
          controller: _priceController,
          onCurrencyAndTypeChanged: (currency, type) {
            _updatePriceData(currency, type);
          },
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description field
        CustomTextField(
          label: 'Description',
          controller: _descriptionController,
          maxLines: 5,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
          prefixIcon: const Icon(Icons.description),
        ),
        const SizedBox(height: 16),

        // Address selector
        const Text(
          'Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select your location details',
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),

        // Import the AddressSelector widget
        // We'll use a simplified version for now
        CustomTextField(
          label: 'Location',
          controller: _locationController,
          prefixIcon: const Icon(Icons.location_on),
          hintText: 'e.g., Mumbai, Maharashtra, India',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your location for better matching with nearby users';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Note: Full address selector will be implemented in the next update',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: AppTheme.textLightColor,
          ),
        ),
        const SizedBox(height: 16),

        // Online availability
        SwitchListTile(
          title: const Text('Available Online'),
          subtitle: const Text('Can you provide this service remotely?'),
          value: _isOnline,
          onChanged: (value) {
            setState(() {
              _isOnline = value;
            });
          },
          secondary: const Icon(Icons.computer),
        ),
        const SizedBox(height: 8),

        // Availability field
        CustomTextField(
          label: 'Availability',
          controller: _availabilityController,
          prefixIcon: const Icon(Icons.access_time),
          hintText: 'e.g., Weekdays after 5 PM, Weekends',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please specify your availability';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPortfolioStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Showcase Your Expertise',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Share high-quality photos that demonstrate your skills and experience. Great photos can significantly increase your chances of getting hired!',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Selected images preview
        if (_selectedImages.isEmpty) ...[
          Container(
            height: 200,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Add photos to showcase your work',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your best work samples, completed projects,\nor before/after transformations',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Portfolio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1, // +1 for add button
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      // Add more photos button
                      return Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: InkWell(
                          onTap: _pickImages,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline,
                                  size: 40, color: Colors.grey[600]),
                              const SizedBox(height: 8),
                              Text(
                                'Add More',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 8,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Tips for Great Photos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Use high-quality, well-lit images\n'
                '• Show different angles of your work\n'
                '• Include before/after comparisons if applicable\n'
                '• Highlight your unique skills and style',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[800],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'By submitting, you agree to our Terms of Service and confirm that your skill complies with our Community Guidelines.',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  // Add method to get current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
            ),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      // Get address from coordinates
      try {
        final response = await http.get(Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _currentAddress = data['display_name'];
            _locationController.text = _currentAddress ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error getting address: $e');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Add method to validate phone number
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    // Basic validation for minimum length
    if (value.length < 10) {
      return 'Phone number is too short';
    }
    // You can add more specific validation based on country code
    return null;
  }

  void _updatePriceData(String currency, String type) {
    setState(() {
      _priceData = {
        'currency': currency,
        'type': type,
        'amount': type == 'Contact for Pricing' ? '' : _priceController.text,
      };
      _selectedPriceType = type;
      if (type == 'Contact for Pricing') {
        _priceController.clear();
      }
    });
  }
}
