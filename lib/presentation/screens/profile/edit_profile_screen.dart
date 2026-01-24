import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.loadProfile();
      
      final user = authProvider.user;
      if (user != null && mounted) {
        _fullNameController.text = user.name;
        _emailController.text = user.email;
        _mobileController.text = user.mobile ?? '';
      }
    } catch (e, stackTrace) {
      debugPrint('[EditProfile] loadProfile error: $e');
      debugPrint('[EditProfile] loadProfile stackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.updateProfile(
        name: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        profilePicture: _selectedImage,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else {
          debugPrint('[EditProfile] updateProfile API error: ${authProvider.errorMessage}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Failed to update profile'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[EditProfile] updateProfile error: $e');
      debugPrint('[EditProfile] updateProfile stackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    // Profile Image Section
                    Center(
                      child: Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          final user = authProvider.user;
                          final profileImageUrl = user?.profileImage;
                          
                          return GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.borderGrey,
                                    border: Border.all(
                                      color: AppColors.primaryBlue,
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _selectedImage != null
                                        ? Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                          )
                                        : profileImageUrl != null && profileImageUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: profileImageUrl,
                                                fit: BoxFit.cover,
                                                width: 120,
                                                height: 120,
                                                placeholder: (context, url) => const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                                errorWidget: (context, url, error) => const Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: AppColors.primaryBlue,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: AppColors.primaryBlue,
                                              ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: AppColors.textWhite,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icons.person,
                validator: Validators.validateName,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _mobileController,
                label: 'Mobile',
                hintText: 'Enter your mobile number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: Validators.validateMobile,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Update Profile',
                onPressed: _isLoading ? null : _updateProfile,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
