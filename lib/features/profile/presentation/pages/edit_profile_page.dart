import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:email_validator/email_validator.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/data/repositories/user_repository.dart';

class EditProfilePage extends StatefulWidget {
  final String initialName;
  final String initialBio;
  final String initialLocation;
  final String initialProfilePic;
  final String? initialCountry;
  final String? initialState;
  final String? initialCity;
  final String? initialHouseNo;
  final String? initialPhone;

  const EditProfilePage({
    super.key,
    required this.initialName,
    required this.initialBio,
    required this.initialLocation,
    required this.initialProfilePic,
    this.initialCountry,
    this.initialState,
    this.initialCity,
    this.initialHouseNo,
    this.initialPhone,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _userRepository = UserRepository();
  bool _isLoading = false;
  String? _profilePicUrl;
  File? _selectedImage;

  // Phone number
  String? _completePhoneNumber;
  bool _isValidPhone = false;

  // Location
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _houseNoController;

  // Add loading overlay controller
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _bioController = TextEditingController(text: widget.initialBio);
    _emailController = TextEditingController(
        text: FirebaseAuth.instance.currentUser?.email ?? '');
    _houseNoController =
        TextEditingController(text: widget.initialHouseNo ?? '');
    _profilePicUrl = widget.initialProfilePic;
    _selectedCountry = widget.initialCountry;
    _selectedState = widget.initialState;
    _selectedCity = widget.initialCity;
    _completePhoneNumber = widget.initialPhone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _houseNoController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Format the location string
      final location = [
        _houseNoController.text.trim(),
        _selectedCity,
        _selectedState,
        _selectedCountry,
      ].where((e) => e != null && e.isNotEmpty).join(', ');

      // Upload profile picture if selected
      String? photoURL = _profilePicUrl;
      if (_selectedImage != null) {
        photoURL = await _userRepository.uploadProfilePicture(_selectedImage!);
      }

      // Update display name in Firebase Auth
      await user.updateDisplayName(_nameController.text.trim());
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Create user document if it doesn't exist
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        // Create the document first
        await userDoc.set({
          'createdAt': FieldValue.serverTimestamp(),
          'uid': user.uid,
        });
      }

      // Update user data in Firestore
      final Map<String, dynamic> updateData = {
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': location,
        'country': _selectedCountry,
        'state': _selectedState,
        'city': _selectedCity,
        'houseNo': _houseNoController.text.trim(),
        'email': _emailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only add phone if it's valid
      if (_completePhoneNumber != null &&
          _completePhoneNumber!.isNotEmpty &&
          _isValidPhone) {
        updateData['phone'] = _completePhoneNumber;
      }

      // Only add photo URL if it exists
      if (photoURL != null) {
        updateData['photoURL'] = photoURL;
      }

      await userDoc.update(updateData);

      if (mounted) {
        Navigator.pop(context, true); // Pass true to indicate successful update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Edit Profile'),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Picture Section
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : (_profilePicUrl != null &&
                                            _profilePicUrl !=
                                                'https://via.placeholder.com/150'
                                        ? NetworkImage(_profilePicUrl!)
                                        : null) as ImageProvider?,
                                child: _selectedImage == null &&
                                        (_profilePicUrl == null ||
                                            _profilePicUrl ==
                                                'https://via.placeholder.com/150')
                                    ? const Icon(Icons.person, size: 50)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt,
                                        color: Colors.white),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return SafeArea(
                                            child: Wrap(
                                              children: <Widget>[
                                                ListTile(
                                                  leading: const Icon(
                                                      Icons.photo_camera),
                                                  title: const Text(
                                                      'Take a photo'),
                                                  onTap: () async {
                                                    Navigator.pop(context);
                                                    final ImagePicker picker =
                                                        ImagePicker();
                                                    try {
                                                      final XFile? image =
                                                          await picker
                                                              .pickImage(
                                                        source:
                                                            ImageSource.camera,
                                                        maxWidth: 1000,
                                                        maxHeight: 1000,
                                                        imageQuality: 85,
                                                      );
                                                      if (image != null &&
                                                          mounted) {
                                                        setState(() {
                                                          _selectedImage =
                                                              File(image.path);
                                                        });
                                                      }
                                                    } catch (e) {
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                              content: Text(
                                                                  'Error taking photo: $e')),
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                                ListTile(
                                                  leading: const Icon(
                                                      Icons.photo_library),
                                                  title: const Text(
                                                      'Choose from gallery'),
                                                  onTap: () async {
                                                    Navigator.pop(context);
                                                    final ImagePicker picker =
                                                        ImagePicker();
                                                    try {
                                                      final XFile? image =
                                                          await picker
                                                              .pickImage(
                                                        source:
                                                            ImageSource.gallery,
                                                        maxWidth: 1000,
                                                        maxHeight: 1000,
                                                        imageQuality: 85,
                                                      );
                                                      if (image != null &&
                                                          mounted) {
                                                        setState(() {
                                                          _selectedImage =
                                                              File(image.path);
                                                        });
                                                      }
                                                    } catch (e) {
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                              content: Text(
                                                                  'Error selecting image: $e')),
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!EmailValidator.validate(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone Field - Made Optional
                        IntlPhoneField(
                          decoration: const InputDecoration(
                            labelText: 'Phone Number (Optional)',
                            border: OutlineInputBorder(),
                            counterText: '',
                            helperText:
                                'Leave empty if you don\'t want to provide a phone number',
                          ),
                          initialCountryCode: 'IN',
                          initialValue: widget.initialPhone
                                  ?.replaceAll(RegExp(r'^\+\d{1,3}'), '') ??
                              '',
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
                            // Allow empty phone number
                            if (value == null || value.number.isEmpty) {
                              _isValidPhone = false;
                              _completePhoneNumber = null;
                              return null;
                            }
                            // Only validate if phone number is provided
                            _isValidPhone = value.isValidNumber();
                            return _isValidPhone
                                ? null
                                : 'Invalid phone number';
                          },
                        ),
                        const SizedBox(height: 16),

                        // Country State City Picker with Improved Performance and Styling
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

                        // House/Flat No Field
                        TextFormField(
                          controller: _houseNoController,
                          decoration: const InputDecoration(
                            labelText: 'House/Flat No., Street',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bio Field
                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.info_outline),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),

                        // Save Button at Bottom
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
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
                            child: _isSaving
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
                                      Icon(Icons.save, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'Save Profile',
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
            ],
          ),
        ),
        if (_isSaving)
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
}
