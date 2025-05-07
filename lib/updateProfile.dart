import 'package:flutter/material.dart';
import 'package:healsearch_app/firebase_database.dart';
import 'package:healsearch_app/profile.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final Flutter_api _api = Flutter_api();
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isSaving = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String? _existingProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userData = await _api.getUserData();

      if (userData != null) {
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text =
              userData['phoneNumber'] ?? userData['phNo'] ?? '';
          _existingProfileImageUrl = userData['profileImage'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load profile data';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading profile: $e';
      });
    }
  }

  // Upload profile image to Firebase Storage
  Future<String?> _uploadProfileImage(File imageFile) async {
    try {
      debugPrint('Starting image upload...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');
      await storageRef.putFile(imageFile).timeout(const Duration(seconds: 20));
      final url = await storageRef.getDownloadURL();
      debugPrint('Image uploaded. URL: ' + url);
      return url;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  // Save updated profile data to Firestore
  Future<void> _updateProfile() async {
    // Validate inputs
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Name cannot be empty');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Phone number cannot be empty');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      debugPrint('Update profile started');
      String? imageUrl = _existingProfileImageUrl;
      if (_profileImage != null) {
        imageUrl = await _uploadProfileImage(_profileImage!);
        if (imageUrl == null) {
          setState(() {
            _isSaving = false;
          });
          _showErrorSnackBar('Failed to upload image.');
          debugPrint('Failed to upload image, aborting update');
          return;
        }
      }
      debugPrint('Calling updateUserProfile with imageUrl: $imageUrl');
      final result = await _api
          .updateUserProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImage: imageUrl,
      )
          .timeout(const Duration(seconds: 20), onTimeout: () {
        debugPrint('updateUserProfile timed out');
        return false;
      });
      debugPrint('updateUserProfile result: $result');
      setState(() {
        _isSaving = false;
      });
      if (result) {
        _showSuccessSnackBar('Profile updated successfully');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Profile()),
        );
      } else {
        _showErrorSnackBar('Failed to update profile');
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Error updating profile: $e';
      });
      _showErrorSnackBar('Error updating profile: $e');
      debugPrint('Exception in _updateProfile: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _profileImage = File(pickedFile.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _profileImage = File(pickedFile.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: const Color.fromARGB(255, 190, 82, 15),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage,
                      style: const TextStyle(color: Colors.red)))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: ClipOval(
                                  child: _profileImage != null
                                      ? Image.file(
                                          _profileImage!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : (_existingProfileImageUrl != null &&
                                              _existingProfileImageUrl!
                                                  .isNotEmpty
                                          ? Image.network(
                                              _existingProfileImageUrl!,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              cacheWidth: 200,
                                              cacheHeight: 200,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.asset(
                                                  "Images/man.png",
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            )
                                          : Image.asset(
                                              "Images/man.png",
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            )),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.white),
                                  onPressed: _pickImage,
                                  color: const Color.fromARGB(255, 190, 82, 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _emailController,
                          readOnly: true, // Email should not be editable
                          enabled: false, // Disable the field
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(188, 255, 140, 0),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Update Profile',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
