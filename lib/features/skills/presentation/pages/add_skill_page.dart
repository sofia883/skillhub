import 'dart:io';
import 'dart:convert';
import 'dart:ui';
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
import '../../../profile/presentation/pages/profile_page.dart';
import '../widgets/price_input.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class AddSkillPage extends StatefulWidget {
  const AddSkillPage({super.key});

  @override
  State<AddSkillPage> createState() => _AddSkillPageState();
}

class _AddSkillPageState extends State<AddSkillPage> {
  late final GlobalKey<FormState> _formKey;
  late final GlobalKey<FormState> _priceFormKey;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _houseNoController = TextEditingController();
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

  // Location
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;

  // Phone number
  String? _completePhoneNumber;
  bool _isValidPhone = false;

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // Add this at the top with other class variables
  bool _shouldValidate = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _priceFormKey = GlobalKey<FormState>();
    _shouldValidate = false;
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
    _houseNoController.dispose();
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

  bool _validateCurrentStep() {
    // Only validate when Next/Submit is clicked
    if (!_shouldValidate) return true;

    bool isValid = true;
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
    });

    switch (_currentStep) {
      case 0: // Basic Info
        if (_titleController.text.isEmpty) {
          isValid = false;
        }
        if (_selectedCategory.isEmpty) {
          isValid = false;
        }
        if (_selectedPriceType != 'Contact for Pricing') {
          if (_priceController.text.isEmpty) {
            isValid = false;
          } else {
            final price = double.tryParse(_priceController.text);
            if (price == null || price <= 0) {
              isValid = false;
            }
          }
        }
        return isValid;

      case 1: // Details
        if (_selectedCountry == null ||
            _selectedState == null ||
            _selectedCity == null) {
          isValid = false;
        }
        if (_availabilityController.text.isEmpty) {
          isValid = false;
        }
        return isValid;

      case 2: // Photos
        return true;

      default:
        return true;
    }
  }

  void _submitSkill() async {
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
    });

    if (!_formKey.currentState!.validate() || !_validateCurrentStep()) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Upload images first
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await Future.wait(
          _selectedImages.map((image) => _uploadImage(image)),
        );
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final skillId = const Uuid().v4();

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
        'rating': 0.0,
        'imageUrl': imageUrls.isNotEmpty
            ? imageUrls.first
            : 'https://via.placeholder.com/300x200?text=No+Image',
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'isFeatured': false,
        'isOnline': _isOnline,
        'availability': _availabilityController.text.trim(),
        'address': {
          'houseNo': _houseNoController.text.trim(),
          'country': _selectedCountry,
          'state': _selectedState,
          'city': _selectedCity,
        },
        'userId': currentUser.uid,
        'providerId': currentUser.uid,
        'provider':
            currentUser.displayName ?? currentUser.email ?? 'Anonymous User',
        'country': _selectedCountry,
        'state': _selectedState,
        'city': _selectedCity,
        if (_completePhoneNumber != null &&
            _completePhoneNumber!.isNotEmpty &&
            _isValidPhone)
          'phone': _completePhoneNumber,
      };

      // Save to Firestore
      await _skillRepository.addSkill(skillData);

      // Navigate immediately after successful save
      if (mounted) {
        // Show a quick success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skill added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Navigate to profile page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfilePage(initialTab: 1),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onStepContinue() {
    setState(() {
      _shouldValidate = true;
    });

    if (_currentStep < _steps.length - 1) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep += 1;
          _shouldValidate = false; // Reset validation flag for next step
        });
      }
    } else {
      _submitSkill();
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
      _houseNoController.clear();
      _availabilityController.clear();
      _selectedCategory = 'Other';
      _selectedSubcategory = '';
      _isOnline = false;
      _selectedImages.clear();
      _currentStep = 0;
      _addressData = null;
    });
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
            title: const Text('Add Your Skill'),
            elevation: 0,
          ),
          body: Form(
            key: _formKey,
            child: Stack(
              children: [
                Stepper(
                  type: StepperType.horizontal,
                  currentStep: _currentStep,
                  onStepTapped: (step) => setState(() => _currentStep = step),
                  onStepContinue: _onStepContinue,
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
              ],
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
          autovalidateMode: _autovalidateMode,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a skill title';
            }
            return null;
          },
          prefixIcon: const Icon(Icons.title),
          errorStyle: const TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 16),

        // Category dropdown
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
            errorStyle: TextStyle(color: Colors.red),
          ),
          value: _selectedCategory,
          autovalidateMode: _autovalidateMode,
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
        Form(
          key: _priceFormKey,
          child: PriceInput(
            controller: _priceController,
            onCurrencyAndTypeChanged: (currency, type) {
              _updatePriceData(currency, type);
            },
            autovalidateMode: _autovalidateMode,
            validator: (value) {
              if (_selectedPriceType != 'Contact for Pricing') {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description field with helper text
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Description (Optional)',
              controller: _descriptionController,
              maxLines: 5,
              autovalidateMode: _shouldValidate
                  ? _autovalidateMode
                  : AutovalidateMode.disabled,
              validator: (value) {
                return null; // Description is optional
              },
              prefixIcon: const Icon(Icons.description),
              errorStyle: const TextStyle(color: Colors.red),
              hintText:
                  'A clear description helps your clients understand your services better...',
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Pro tip: Include your experience, specialties, and what makes your service unique',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Phone Field with clear optional label
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntlPhoneField(
              decoration: const InputDecoration(
                labelText: 'Phone Number (Optional)',
                border: OutlineInputBorder(),
                counterText: '',
                helperText:
                    'Add your phone number if you want clients to call you directly',
                errorStyle: TextStyle(color: Colors.red),
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
              onCountryChanged: (country) {
                debugPrint('Country changed to: ${country.name}');
              },
              validator: (value) {
                if (value == null || value.number.isEmpty) {
                  return null;
                }
                return value.isValidNumber() ? null : 'Invalid phone number';
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // House number field with clear optional label
        CustomTextField(
          label: 'House/Flat No. (Optional)',
          controller: _houseNoController,
          hintText: 'e.g., A-123, Flat 4B',
          prefixIcon: const Icon(Icons.home),
          autovalidateMode:
              _shouldValidate ? _autovalidateMode : AutovalidateMode.disabled,
          helperText: 'Add your house/flat number for in-person services',
        ),
        const SizedBox(height: 24),

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

        // Country State City Picker with validation message
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              if (_autovalidateMode == AutovalidateMode.always &&
                  (_selectedCountry == null ||
                      _selectedState == null ||
                      _selectedCity == null))
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    'Please select your location (country, state, and city)',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Online availability
        SwitchListTile(
          title: Text(
            'Available Online',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          subtitle: Text(
            'Can you provide this service remotely?',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.textSecondaryColor,
            ),
          ),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Availability',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(
                    'All Time',
                    style: TextStyle(fontSize: AppTheme.fontSizeSmall),
                  ),
                  selected: _availabilityController.text == 'All Time',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _availabilityController.text = 'All Time';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: Text(
                    'Weekends Only',
                    style: TextStyle(fontSize: AppTheme.fontSizeSmall),
                  ),
                  selected: _availabilityController.text == 'Weekends Only',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _availabilityController.text = 'Weekends Only';
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: Text(
                    'Weekdays Only',
                    style: TextStyle(fontSize: AppTheme.fontSizeSmall),
                  ),
                  selected: _availabilityController.text == 'Weekdays Only',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _availabilityController.text = 'Weekdays Only';
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            CustomTextField(
              label: 'Availability',
              controller: _availabilityController,
              prefixIcon: const Icon(Icons.access_time),
              hintText: 'Or specify custom timing...',
              autovalidateMode: _shouldValidate
                  ? _autovalidateMode
                  : AutovalidateMode.disabled,
              validator: (value) {
                if (_shouldValidate && (value == null || value.isEmpty)) {
                  return 'Please specify your availability';
                }
                return null;
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Showcase Your Expertise (Optional)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Share high-quality photos that demonstrate your skills and experience. While optional, great photos can significantly increase your chances of getting hired!',
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

  Future<String> _uploadImage(File image) async {
    try {
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
          return jsonResponse['data']['display_url'];
        } else {
          throw Exception('Image upload failed: ${jsonResponse['error']}');
        }
      } else {
        throw Exception(
            'Image upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image');
    }
  }
}
