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
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _selectedAvatarId;
  List<AvatarModel> _avatars = [];
  bool _isLoading = false;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
      _loadAvatarsForPreview();
    });
  }

  Future<void> _loadAvatarsForPreview() async {
    try {
      final response = await ApiService.getAvatars(page: 1, limit: 10);
      if (mounted && response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<dynamic> dataList;
        if (data is List) {
          dataList = data;
        } else if (data is Map && data['results'] != null) {
          dataList = data['results'] as List<dynamic>;
        } else if (data is Map && data['avatars'] != null) {
          dataList = data['avatars'] as List<dynamic>;
        } else {
          dataList = [];
        }
        setState(() {
          _avatars = dataList
              .map((e) => AvatarModel.fromJson(e as Map<String, dynamic>))
              .where((a) => a.isActive)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('[EditProfile] _loadAvatarsForPreview error: $e');
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
        if (user.avatarId != null && user.avatarId!.isNotEmpty) {
          _selectedAvatarId = user.avatarId;
          _selectedImage = null;
        }
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

  void _showChangeProfilePictureDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _ChangeProfilePictureDialog(
        selectedAvatarId: _selectedAvatarId,
        onAvatarSelected: (avatar) {
          _selectAvatar(avatar);
          Navigator.of(dialogContext).pop();
        },
        onGalleryTap: () async {
          Navigator.of(dialogContext).pop();
          await _pickImageFromGallery();
        },
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
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
        mobile: null,
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
                    // Profile Image Section with Edit Icon
                    Center(
                      child: GestureDetector(
                        onTap: _showChangeProfilePictureDialog,
                        child: Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            final user = authProvider.user;
                            final profileImageUrl = user?.profileImage;
                            String? displayImageUrl;
                            if (_selectedAvatarId != null) {
                              for (var a in _avatars) {
                                if (a.id == _selectedAvatarId) {
                                  displayImageUrl = a.fullImageUrl;
                                  break;
                                }
                              }
                            }
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.borderGrey,
                                    border: Border.all(
                                      color: AppColors.primaryBlue,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _selectedImage != null
                                        ? Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                            width: 64,
                                            height: 64,
                                          )
                                        : displayImageUrl != null &&
                                                displayImageUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: displayImageUrl,
                                                fit: BoxFit.cover,
                                                width: 64,
                                                height: 64,
                                                placeholder: (context, url) =>
                                                    const Center(
                                                  child: CircularProgressIndicator(
                                                      strokeWidth: 2),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(
                                                  Icons.person,
                                                  size: 32,
                                                  color: AppColors.primaryBlue,
                                                ),
                                              )
                                            : profileImageUrl != null &&
                                                    profileImageUrl.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: profileImageUrl,
                                                    fit: BoxFit.cover,
                                                    width: 64,
                                                    height: 64,
                                                    placeholder:
                                                        (context, url) =>
                                                            const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            const Icon(
                                                      Icons.person,
                                                      size: 32,
                                                      color: AppColors
                                                          .primaryBlue,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.person,
                                                    size: 32,
                                                    color: AppColors.primaryBlue,
                                                  ),
                                  ),
                                ),
                                // Edit icon overlay
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: GestureDetector(
                                    onTap: _showChangeProfilePictureDialog,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.backgroundWhite,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        size: 14,
                                        color: AppColors.textWhite,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showChangeProfilePictureDialog,
                      child: const Text(
                        'Change profile picture',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
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
                label: 'Email or Phone',
                hintText: 'Enter your email or phone',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.text,
                validator: Validators.validateEmailOrPhone,
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

/// Dialog that loads avatars from GET {{baseUrl}}/avatars?page=1&limit=10
/// and shows them - selected image is set as profile picture
class _ChangeProfilePictureDialog extends StatefulWidget {
  final String? selectedAvatarId;
  final void Function(AvatarModel avatar) onAvatarSelected;
  final VoidCallback onGalleryTap;

  const _ChangeProfilePictureDialog({
    required this.selectedAvatarId,
    required this.onAvatarSelected,
    required this.onGalleryTap,
  });

  @override
  State<_ChangeProfilePictureDialog> createState() =>
      _ChangeProfilePictureDialogState();
}

class _ChangeProfilePictureDialogState extends State<_ChangeProfilePictureDialog> {
  List<AvatarModel> _avatars = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService.getAvatars(page: 1, limit: 10);
      if (!mounted) return;
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<dynamic> dataList;
        if (data is List) {
          dataList = data;
        } else if (data is Map && data['results'] != null) {
          dataList = data['results'] as List<dynamic>;
        } else if (data is Map && data['avatars'] != null) {
          dataList = data['avatars'] as List<dynamic>;
        } else {
          dataList = [];
        }
        setState(() {
          _avatars = dataList
              .map((e) => AvatarModel.fromJson(e as Map<String, dynamic>))
              .where((a) => a.isActive)
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message']?.toString() ?? 'Failed to load avatars';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[AvatarDialog] _loadAvatars error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.of(context).size.width * 0.85;
    const crossAxisCount = 4;
    const spacing = 10.0;
    final itemSize = (dialogWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
    return AlertDialog(
      title: const Text('Change Profile Picture'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loadAvatars,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_avatars.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No avatars available',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            )
          else
            SizedBox(
              width: dialogWidth,
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                  children: _avatars.map((avatar) {
                    final isSelected = widget.selectedAvatarId == avatar.id;
                    final imageUrl = avatar.fullImageUrl;
                    return SizedBox(
                      width: itemSize,
                      height: itemSize,
                      child: GestureDetector(
                        onTap: () => widget.onAvatarSelected(avatar),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.borderGrey,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: ClipOval(
                            child: imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    width: itemSize,
                                    height: itemSize,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(
                                      Icons.person,
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: AppColors.textSecondary,
                                  ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
              ),
            ),
          if (_avatars.isNotEmpty) const SizedBox(height: 16),
          const Text(
            'Or choose from gallery',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onGalleryTap,
              icon: const Icon(Icons.photo_library_outlined, size: 20),
              label: const Text('Choose from Gallery'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
