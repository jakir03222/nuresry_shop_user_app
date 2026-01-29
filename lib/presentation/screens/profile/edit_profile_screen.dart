import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/avatar_model.dart';
import '../../../data/services/api_service.dart';
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
  String? _selectedAvatarId;
  List<AvatarModel> _avatars = [];
  bool _isLoadingAvatars = false;
  bool _isLoading = false;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
      _loadAvatars();
    });
  }

  Future<void> _loadAvatars() async {
    setState(() => _isLoadingAvatars = true);
    try {
      final response = await ApiService.getAvatars(page: 1, limit: 10);
      if (mounted && response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        setState(() {
          _avatars = data
              .map((e) => AvatarModel.fromJson(e as Map<String, dynamic>))
              .where((a) => a.isActive)
              .toList();
          _isLoadingAvatars = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingAvatars = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAvatars = false);
    }
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

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedAvatarId = null;
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

  void _selectAvatar(AvatarModel avatar) {
    setState(() {
      _selectedAvatarId = avatar.id;
      _selectedImage = null;
    });
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
        avatarId: _selectedAvatarId,
        profilePicture: _selectedImage,
      );

      if (mounted) {
        if (success) {
          // Reload profile to get updated image immediately (from cache first, then API)
          await authProvider.loadProfile(forceRefresh: true);
          
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
                    // Profile Image Section (preview: selected avatar, gallery image, or current)
                    Center(
                      child: Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          final user = authProvider.user;
                          final profileImageUrl = user?.profileImage;
                          String? displayImageUrl;
                          if (_selectedAvatarId != null) {
                            for (var a in _avatars) {
                              if (a.id == _selectedAvatarId) {
                                displayImageUrl = a.imageUrl;
                                break;
                              }
                            }
                          }
                          return Stack(
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
                                      : displayImageUrl != null && displayImageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: displayImageUrl,
                                              fit: BoxFit.cover,
                                              width: 120,
                                              height: 120,
                                              placeholder: (context, url) => const Center(
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                              errorWidget: (context, url, error) => const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: AppColors.primaryBlue,
                                              ),
                                            )
                                          : profileImageUrl != null && profileImageUrl.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: profileImageUrl,
                                                  fit: BoxFit.cover,
                                                  width: 120,
                                                  height: 120,
                                                  placeholder: (context, url) => const Center(
                                                    child: CircularProgressIndicator(strokeWidth: 2),
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
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Change profile picture',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Avatars from API: GET {{baseUrl}}/avatars?page=1&limit=10
                    const Text(
                      'Choose an avatar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingAvatars)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (_avatars.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: const Text(
                          'No avatars available',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.95,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _avatars.length,
                        itemBuilder: (context, index) {
                          final avatar = _avatars[index];
                          final isSelected = _selectedAvatarId == avatar.id;
                          return GestureDetector(
                            onTap: () => _selectAvatar(avatar),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryBlue : AppColors.borderGrey,
                                  width: isSelected ? 3 : 1,
                                ),
                              ),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: avatar.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.person),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    // Gallery option
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(Icons.photo_library_outlined, size: 20),
                        label: const Text('Choose from Gallery'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: AppColors.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                label: 'Mobile (optional)',
                hintText: 'Enter your mobile number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: Validators.validateMobileOptional,
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
