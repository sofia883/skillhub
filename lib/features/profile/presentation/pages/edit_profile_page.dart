import 'dart:io';
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
    if (!_isValidPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
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

      // Update user data in Firestore
      await _userRepository.updateUserData(user.uid, {
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': location,
        'country': _selectedCountry,
        'state': _selectedState,
        'city': _selectedCity,
        'houseNo': _houseNoController.text.trim(),
        'phone': _completePhoneNumber,
        'email': _emailController.text.trim(),
        if (photoURL != null) 'photoURL': photoURL,
      });

      if (mounted) {
        Navigator.pop(context);
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: SingleChildScrollView(
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
                                          leading:
                                              const Icon(Icons.photo_camera),
                                          title: const Text('Take a photo'),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            final ImagePicker picker =
                                                ImagePicker();
                                            try {
                                              final XFile? image =
                                                  await picker.pickImage(
                                                source: ImageSource.camera,
                                                maxWidth: 1000,
                                                maxHeight: 1000,
                                                imageQuality: 85,
                                              );
                                              if (image != null && mounted) {
                                                setState(() {
                                                  _selectedImage =
                                                      File(image.path);
                                                });
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
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
                                          leading:
                                              const Icon(Icons.photo_library),
                                          title:
                                              const Text('Choose from gallery'),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            final ImagePicker picker =
                                                ImagePicker();
                                            try {
                                              final XFile? image =
                                                  await picker.pickImage(
                                                source: ImageSource.gallery,
                                                maxWidth: 1000,
                                                maxHeight: 1000,
                                                imageQuality: 85,
                                              );
                                              if (image != null && mounted) {
                                                setState(() {
                                                  _selectedImage =
                                                      File(image.path);
                                                });
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
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

                // Phone Field
                IntlPhoneField(
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    counterText: '',
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
                    _completePhoneNumber = phone.completeNumber;
                  },
                  onCountryChanged: (country) {
                    debugPrint('Country changed to: ${country.name}');
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please enter a phone number';
                    }
                    _isValidPhone = value.isValidNumber();
                    return _isValidPhone ? null : 'Invalid phone number';
                  },
                ),
                const SizedBox(height: 16),

                // Country State City Picker
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      SelectState(
                        onCountryChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                            _selectedState = null;
                            _selectedCity = null;
                          });
                        },
                        onStateChanged: (value) {
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
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 14,
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
