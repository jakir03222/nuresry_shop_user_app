import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleCreateAccount() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      
      setState(() {
        _isLoading = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        profileImage: _profileImage,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.successMessage ?? 
                'Account created successfully! Please verify your email.',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          context.push('/otp-verification?email=${Uri.encodeComponent(_emailController.text.trim())}');
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Account creation failed'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildUnderlineTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.6),
          fontSize: 16,
        ),
        suffixIcon: suffixIcon,
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.borderGrey,
            width: 1,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.borderGrey,
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.primaryBlue,
            width: 2,
          ),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Profile Image with Upload
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryBlue,
                            border: Border.all(
                              color: AppColors.primaryBlue,
                              width: 3,
                            ),
                          ),
                          child: _profileImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    _profileImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.textWhite,
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  const Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    'From groceries to important projects\nwe help you to remember it all.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Name Field
                  _buildUnderlineTextField(
                    controller: _nameController,
                    hintText: 'Name',
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 24),
                  // Email Field
                  _buildUnderlineTextField(
                    controller: _emailController,
                    hintText: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 24),
                  // Phone Field
                  _buildUnderlineTextField(
                    controller: _phoneController,
                    hintText: 'Phone number',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.length < 10) {
                        return 'Phone number must be at least 10 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Password Field
                  _buildUnderlineTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: _obscurePassword,
                    validator: Validators.validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Confirm Password Field
                  _buildUnderlineTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: _obscureConfirmPassword,
                    validator: (value) => Validators.validateConfirmPassword(
                      value,
                      _passwordController.text,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleCreateAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.textWhite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.textWhite,
                                ),
                              ),
                            )
                          : const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have account? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
