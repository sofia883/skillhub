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
  final _phoneNumberController = TextEditingController();
  final _skillRepository = SkillRepository();

  // Address data
  Map<String, dynamic>? _addressData;

  String _selectedCategory = 'Other';
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

  String _selectedSubcategory = '';

  @override
  void initState() {
    super.initState();
    // Initialize default subcategory
    _updateSubcategories(_selectedCategory);
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
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _updateSubcategories(String category) {
    if (subcategories.containsKey(category) &&
        subcategories[category]!.isNotEmpty) {
      setState(() {
        _selectedSubcategory = subcategories[category]![0];
      });
    }
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
        _priceController.text.isEmpty) {
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

      // Create skill data
      final skillData = {
        'id': skillId,
        'title': _titleController.text.trim(),
        'description': _generateDescription(),
        'category': _selectedCategory,
        'subcategory': _selectedSubcategory,
        'price': price,
        'rating': 0.0, // New skills start with no rating
        'imageUrl': imageUrls.isNotEmpty
            ? imageUrls.first
            : 'https://via.placeholder.com/300x200?text=No+Image',
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'isFeatured': false,
        'location': _locationController.text.trim(),
        'isOnline': _isOnline,
        'availability': _availabilityController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'address': _addressData,
        'userId':
            currentUser?.uid ?? 'unknown_user', // Important for security rules
        'providerId': currentUser?.uid ?? 'unknown_user',
        'provider':
            currentUser?.displayName ?? currentUser?.email ?? 'Anonymous User',
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
              // Return to previous screen with a result to trigger refresh
              Navigator.of(context).pop(true); // Pass true to indicate success
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Your Skill'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepTapped: (step) => setState(() => _currentStep = step),
            onStepContinue: () {
              final isLastStep = _currentStep == _steps.length - 1;
              if (isLastStep) {
                // For the last step, only check if images are successfully uploaded
                _submitSkill();
              } else {
                // Validate the current step before proceeding
                bool isValid = true;
                String errorMessage = '';

                // Check validation based on current step
                if (_currentStep == 0) {
                  // Validate basic info fields
                  if (_titleController.text.isEmpty) {
                    isValid = false;
                    errorMessage = 'Please enter a skill title';
                  } else if (_priceController.text.isEmpty) {
                    isValid = false;
                    errorMessage = 'Please enter a price';
                  } else if (double.tryParse(_priceController.text) == null) {
                    isValid = false;
                    errorMessage = 'Please enter a valid price';
                  }
                } else if (_currentStep == 1) {
                  // Validate details fields
                  if (_descriptionController.text.isEmpty) {
                    isValid = false;
                    errorMessage = 'Please enter a description';
                  } else if (_locationController.text.isEmpty) {
                    isValid = false;
                    errorMessage = 'Please enter your location';
                  } else if (_availabilityController.text.isEmpty) {
                    isValid = false;
                    errorMessage = 'Please specify your availability';
                  }
                }

                if (!isValid) {
                  // Show error message with amber color instead of red
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
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
                } else {
                  setState(() => _currentStep += 1);
                }
              }
            },
            onStepCancel: _currentStep == 0
                ? null // Disable on first step
                : () => setState(() => _currentStep -= 1),
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == _steps.length - 1;

              return Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (_currentStep != 0)
                          Expanded(
                            child: CustomButton(
                              text: 'Back',
                              onPressed: details.onStepCancel!,
                              isOutlined: true,
                            ),
                          ),
                        if (_currentStep != 0) const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: isLastStep ? 'Submit' : 'Next',
                            onPressed: details.onStepContinue!,
                            isLoading: _isLoading || _isUploadingImages,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            steps: _steps,
          ),
        ),
      ),
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
        if (subcategories.containsKey(_selectedCategory)) ...[
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Specialty',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.topic),
            ),
            value: _selectedSubcategory,
            items: subcategories[_selectedCategory]!.map((subcategory) {
              return DropdownMenuItem(
                value: subcategory,
                child: Text(subcategory),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSubcategory = value!;
              });
            },
          ),
          const SizedBox(height: 16),
        ],

        // Price field
        CustomTextField(
          label: 'Price per hour (USD)',
          controller: _priceController,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a price';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
          prefixIcon: const Icon(Icons.attach_money),
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

        // Phone number field
        CustomTextField(
          label: 'Phone Number',
          controller: _phoneNumberController,
          prefixIcon: const Icon(Icons.phone),
          hintText: 'e.g., +91 9876543210',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number for clients to contact you';
            }
            return null;
          },
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
          'Add photos of your work',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Show examples of your previous work to attract more clients',
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Selected images preview
        if (_selectedImages.isEmpty) ...[
          Container(
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate,
                    size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No images selected',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ] else ...[
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
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
}
