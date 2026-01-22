import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/character_counter.dart';
import '../../widgets/auth/auth_header.dart';
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleCreateAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.successMessage ?? 'Account created successfully. Please verify your email.'),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate to OTP verification screen
          context.push('/otp-verification?email=${Uri.encodeComponent(_emailController.text.trim())}');
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Account creation failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              AuthHeader(
                title: AppStrings.createAccount,
                subtitle: AppStrings.signUpToGetStarted,
                illustration: _buildIllustration(),
              ),
              // Form Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // Name Field
                      CustomTextField(
                        hintText: AppStrings.fullName,
                        prefixIcon: Icons.person_outline,
                        controller: _nameController,
                        validator: Validators.validateName,
                        maxLength: AppConstants.nameMaxLength,
                      ),
                      const SizedBox(height: 16),
                      // Email Field
                      CustomTextField(
                        hintText: AppStrings.email,
                        prefixIcon: Icons.email_outlined,
                        controller: _emailController,
                        validator: Validators.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      // Password Field
                      CustomTextField(
                        hintText: AppStrings.password,
                        prefixIcon: Icons.lock_outline,
                        controller: _passwordController,
                        validator: Validators.validatePassword,
                        obscureText: _obscurePassword,
                        maxLength: AppConstants.passwordMaxLength,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CharacterCounter(
                                currentLength: _passwordController.text.length,
                                maxLength: AppConstants.passwordMaxLength,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Confirm Password Field
                      CustomTextField(
                        hintText: AppStrings.confirmPassword,
                        prefixIcon: Icons.lock_outline,
                        controller: _confirmPasswordController,
                        validator: (value) => Validators.validateConfirmPassword(
                          value,
                          _passwordController.text,
                        ),
                        obscureText: _obscureConfirmPassword,
                        maxLength: AppConstants.passwordMaxLength,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CharacterCounter(
                                currentLength: _confirmPasswordController.text.length,
                                maxLength: AppConstants.passwordMaxLength,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Create Account Button
                      CustomButton(
                        text: AppStrings.createAccount,
                        onPressed: _handleCreateAccount,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),
                      // Sign In Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            AppStrings.alreadyHaveAccount,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.pop();
                            },
                            child: const Text(
                              AppStrings.signIn,
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.primaryBlueLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.person_add,
        size: 100,
        color: AppColors.textWhite,
      ),
    );
  }
}
