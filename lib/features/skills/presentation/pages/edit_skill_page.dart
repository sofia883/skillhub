import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../features/home/data/repositories/skill_repository.dart';
import '../../../../features/home/domain/entities/skill.dart';

class EditSkillPage extends StatefulWidget {
  final Skill skill;

  const EditSkillPage({
    super.key,
    required this.skill,
  });

  @override
  State<EditSkillPage> createState() => _EditSkillPageState();
}

class _EditSkillPageState extends State<EditSkillPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  final _skillRepository = SkillRepository();

  String _selectedCategory = 'Other';
  bool _isLoading = false;
  bool _isUploadingImages = false;
  final List<File> _selectedImages = [];
  final _imagePicker = ImagePicker();

  // ImgBB API key - same as used in AddSkillPage
  final String _imgbbApiKey = "0c58b6d9015713886842dab7d4825812";

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing skill data
    _titleController = TextEditingController(text: widget.skill.title);
    _descriptionController =
        TextEditingController(text: widget.skill.description);
    _priceController =
        TextEditingController(text: widget.skill.price.toString());
    _locationController =
        TextEditingController(text: widget.skill.location ?? '');
    _selectedCategory = widget.skill.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
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

  Future<void> _updateSkill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload new images if any were selected
      List<String> newImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        newImageUrls = await _uploadImages();
      }

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare skill data
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

      // Use the first new image as the main image, or keep the existing one
      final mainImageUrl =
          newImageUrls.isNotEmpty ? newImageUrls[0] : widget.skill.imageUrl;

      final skillData = {
        'id': widget.skill.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'price': price,
        'imageUrl': mainImageUrl,
        'location': _locationController.text.trim(),
        'userId': user.uid,
        'providerId': user.uid,
        'provider': user.displayName ?? user.email ?? 'Anonymous User',
      };

      // Add additional images if available
      if (newImageUrls.length > 1) {
        skillData['additionalImages'] = newImageUrls.sublist(1);
      }

      // Update skill
      final success = await _skillRepository.addSkill(skillData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update skill')),
        );
      }
    } catch (e) {
      debugPrint('Error updating skill: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating skill: $e')),
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
        title: const Text('Edit Skill'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Images section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Skill Images',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Current main image or placeholder
                        if (_selectedImages.isEmpty)
                          Center(
                            child: GestureDetector(
                              onTap: () => _showImageSourceDialog(),
                              child: Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  image: widget.skill.imageUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              widget.skill.imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (widget.skill.imageUrl.isEmpty)
                                      const Icon(
                                        Icons.add_photo_alternate,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(top: 120),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withAlpha(153), // 0.6 opacity
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Tap to add images',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Selected images preview
                        if (_selectedImages.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImages.length +
                                      1, // +1 for add button
                                  itemBuilder: (context, index) {
                                    if (index == _selectedImages.length) {
                                      // Add more images button
                                      return GestureDetector(
                                        onTap: () => _showImageSourceDialog(),
                                        child: Container(
                                          width: 150,
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Add More',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    // Image preview with remove button
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 150,
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            image: DecorationImage(
                                              image: FileImage(
                                                  _selectedImages[index]),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 5,
                                          right: 13,
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
                                                color: Colors.white,
                                                size: 16,
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
                    ),
                    const SizedBox(height: 24),

                    // Title field
                    CustomTextField(
                      controller: _titleController,
                      label: 'Title',
                      hintText: 'Enter skill title',
                      prefixIcon: const Icon(Icons.title),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hintText: 'Enter skill description',
                      prefixIcon: const Icon(Icons.description),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      items: [
                        'Programming',
                        'Design',
                        'Marketing',
                        'Writing',
                        'Music',
                        'Video',
                        'Photography',
                        'Business',
                        'Lifestyle',
                        'Education',
                        'Other',
                      ].map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price field
                    CustomTextField(
                      controller: _priceController,
                      label: 'Price (\$)',
                      hintText: 'Enter price',
                      prefixIcon: const Icon(Icons.attach_money),
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
                    ),
                    const SizedBox(height: 16),

                    // Location field
                    CustomTextField(
                      controller: _locationController,
                      label: 'Location',
                      hintText: 'Enter location (optional)',
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                    const SizedBox(height: 24),

                    // Update button
                    CustomButton(
                      text: 'Update Skill',
                      onPressed: _updateSkill,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
          ],
        ),
      ),
    );
  }
}
